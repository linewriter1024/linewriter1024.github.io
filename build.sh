#!/bin/bash

set -e

tmp="$(mktemp -d)"

finish() {
	echo "Done, removing $tmp"
	rm -r "$tmp"
}

trap finish EXIT

# Akas are permanent names that redirect to various resources. If the location of the resource changes, the aka can simply be updated.
# Due to being hosted on Github pages we do not have direct control over redirects, so we must use meta refresh directives.
echo "Akas..."

mkdir -p aka

# Each line in akas.txt has the format:
# <name of redirect> <url of redirect>
while read line; do
	# Split the aka line into the name and url
	name="$(echo "$line" | cut -d' ' -f1)"
	url="$(echo "$line" | cut -d' ' -f2-)"

	echo " $name -> $url"

	(

		file="aka/$name.html"

		echo "<!DOCTYPE html>" > $file
		echo "<title>Redirecting to $url</title>" >> $file

		# Refresh the page immediately to the desired URL.
		echo "<meta http-equiv='refresh' content='0; URL=$url'>" >> $file

		# However, we don't want any caching, so if we update the URL it will be immediately reflected in the redirect.
		echo '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />' >> $file
		echo '<meta http-equiv="Pragma" content="no-cache" />' >> $file
		echo '<meta http-equiv="Expires" content="0" />' >> $file

		# Additional links to the URL.
		echo "<link rel='canonical' href='$url'>" >> $file
		echo "Redirecting to <a href='$url'>$url</a>..." >> $file # The user can click this one if their browser doesn't redirect them.
	) &
done < akas.txt

echo "Downloading images..."
while read line; do
	output="$(echo "$line" | cut -d' ' -f1)"
	input="$(echo "$line" | cut -d' ' -f2-)"

	echo " Downloading $input -> $output"

	curl -sSL "$input" > "images/$output" &
done < images.txt

# replacefile <placeholder> <path to file>
# A pipeline function to replace a placeholder with the contents of a file
replacefile() {
	placeholder="$1"
	path="$2"

	python3 -u -c "import sys; sys.stdout.write(sys.stdin.read().replace(sys.argv[1], open(sys.argv[2]).read()))" "$placeholder" "$path"
}

# replacetext <placeholder> <text to insert>
# A pipeline function to replace a placeholder with text
replacetext() {
	placeholder="$1"
	text="$2"

	python3 -u -c "import sys; sys.stdout.write(sys.stdin.read().replace(sys.argv[1], sys.argv[2]))" "$placeholder" "$text"
}

htmlescape() {
	python3 -c "import html, sys; sys.stdout.write(html.escape(sys.stdin.read()))"
}

basereplace() {
	toroot="$1"

	replacetext "__RDATE__" "$(TZ=UTC date -R)" |
	replacetext "__YEAR__" "$(TZ=UTC date +%Y)" |
	replacetext "__DATE__" "$(TZ=UTC date -I)" |
	replacetext "__ROOT__" "$toroot"
}

commonreplace() {
	basereplace "$@" |
	replacetext "__FOOTERICONS__" "$(basereplace "$@" < templates/footer_icons.in.html)"
}

mkdir -p blog/tags
mkdir -p "$tmp"/tags

# The list of all tags, to be built up as posts are processed.
alltags=""

# Maximum blog posts in the "minor" list, i.e. on the front page.
BMMAX=5

# Maximum number of words in the RSS description summary
SUMMARY_WORDS=100

# Number of blog posts so far.
BN=0

echo "Blog..."

# Begin the major and minor blog post lists.
echo "<ul>" > "$tmp"/_major.in.html
echo "<ul>" > "$tmp"/_minor.in.html

# The post function is called from the posts.sh list of posts; it is responsible for processing each blog post.
# A post has four components, reflected in the arguments:
# post <human-redable identifier name> <human-readable, pretty title of post> <date YYYY-MM-DD> <space-delimited list of tags>
post() {
	name="$1"
	title="$2"
	date="$3"
	tags="$4"

	series="$POST_SERIES"

	# We'll be reading the text of the blog post from an input HTML file and generating the full HTML page.
	infile="blog.in/$name.in.html"
	outfile="blog/$name.html"
	outfeed="$tmp/_$name.xml"

	echo " $name: $title [$date]"

	# We will collect all the tags and build a list of hyperlinks to insert into the HTML.
	# HTML for the tag lists are generated for each different place they must be used with different styling and URLs (since sometimes we need blog/tags#tag and sometimes just tags/#tag if we are within the blog itself).

	taghtml="" # The list of tags to be used within the blog posts.
	smalltaghtml="" # The list of tags to be used within the "major" blog post list, on the dedicated blog page.
	minortaghtml="" # The list of tags to be used within the "minor" blog post list, on the main page.

	while read tag; do
		taghtml="$taghtml <a class='tag' href='__ROOT__/blog/tags/$tag'>#$tag</a>"
		minortaghtml="$minortaghtml <a class='smalltag' href='__ROOT__/blog/tags/$tag'>#$tag</a>"
		smalltaghtml="$smalltaghtml <a class='smalltag' href='__ROOT__/blog/tags/$tag'>#$tag</a>"

		# If we haven't seen this tag yet in any post, record it and clear away any old file built from this tag.
		if ! echo "$alltags" | grep -w "$tag" > /dev/null; then
			echo " New tag: $tag"
			alltags="$alltags $tag"
		fi

	done < <(echo "$tags" | xargs -n1 | sort | uniq | xargs -n1 --no-run-if-empty)

	# Now we will write a link to this post to the each of its tags' pages.
	# We do this after tag processing because a link to the post also includes its tags, so we need to know all the tags of the post.
	while read tag; do
		echo "<li class='postlisting'><a href='__ROOT__/blog/$name'>$title</a> [$date] $smalltaghtml</li>" >> "$tmp/_tag_$tag.html"
	done < <(echo "$tags" | xargs -n1 --no-run-if-empty)

	# Record that another post was processed.
	BN=$((BN+1))

	# If we haven't reached the limit for "minor" posts, add a link to the minor blog post listing HTML, this is for the "recent posts" section of the main page.
	if [ $BN -le $BMMAX ]; then
		echo "<li class='postlisting'><a href='__ROOT__/blog/$name'>$title</a> [$date] $minortaghtml</li>" >> "$tmp"/_minor.in.html
	fi

	# Always add a link to the "major" blog post listing HTML, this is for the dedicated blog page.
	echo "<li class='postlisting'><a href='__ROOT__/blog/$name'>$title</a> [$date] $smalltaghtml</li>" >> "$tmp"/_major.in.html

	replaceseries() {
		if [[ -n "$series" ]]; then
			replacefile "__SERIES_TOP__" "templates/series_top.in.html" | replacefile "__SERIES_BOTTOM__" "templates/series_bottom.in.html" | replacetext "__SERIES__" "$series" | replacetext "__SERIES_RSS_LINK__" "<link rel='alternate' type='application/rss+xml' title=\"Ben Leskey's RSS feed: $series\" href='tags/$series.feed.xml'>"
		else
			replacetext "__SERIES_TOP__" "" | replacetext "__SERIES_BOTTOM__" "" | replacetext "__SERIES_RSS_LINK__" ""
		fi
	}

	# Build the blog post HTML.
	(replacetext "__TITLE__" "$title" | replacetext "__POST_DATE__" "$date" | replacetext "__TAGS__" "$taghtml" | replaceseries | commonreplace .. | replacefile "__POST__" "$infile" | python3 toc_builder.py) < templates/post.in.html > "$outfile" &

	summary() {
		< "$infile" pandoc -i - -o - -t plain | xargs | cut -d' ' -f -$SUMMARY_WORDS
	}

	# Build the RSS item XML
	(commonreplace .. | replacetext "__TITLE__" "$title" | replacetext "__POST_RDATE__" "$(TZ=UTC date --date="$date + 12 hours" -R)" | replacetext "__CATEGORIES__" "$(echo "$tags" | xargs -n1 printf "<category>%s</category>")" | replacetext "__LINK__" "https://benleskey.com/blog/$name" | replacetext "__DESCRIPTION__" "$(summary | htmlescape)…") < templates/feed_item.in.xml > "$outfeed" &
}

# Include the list of posts via source, so it can call the post function.
source blog.in/posts.sh

# If there are more posts than can be displayed in the minor list (on the main page) then add a "More..." link to the minor list.
if [ $BN -gt $BMMAX ]; then
	echo "<li><a href='blog'>$((BN - BMMAX)) more...</a></li>" >> "$tmp"/_minor.in.html
fi

# Cap off the lists.
echo "</ul>" >> "$tmp"/_minor.in.html
echo "</ul>" >> "$tmp"/_major.in.html

echo " Waiting..."
wait

echo "" > "$tmp"/_feed.in.xml

# Concat all the RSS items
post() {
	name="$1"
	tags="$4"

	feedfile="$tmp/_$name.xml"
	cat < "$feedfile" >> "$tmp"/_feed.in.xml

	while read tag; do
		cat < "$feedfile" >> "$tmp"/_tag_feed_"$tag".xml
	done < <(echo "$tags" | xargs -n1 --no-run-if-empty)

}

source blog.in/posts.sh

# Build the main page.
(
	replacefile "__BLOGMINOR__" "$tmp/_minor.in.html" |
	commonreplace .
) < templates/index.in.html > index.html

# Build the dedicated blog index page.
(replacefile "__BLOGMAJOR__" "$tmp/_major.in.html" | replacetext __NUM_POSTS__ "$BN" | commonreplace ..) < templates/blog.in.html > blog/index.html


# Uniquify and sort the list of all tags.
alltags="$(echo "$alltags" | xargs -n1 | sort | uniq | xargs)"

# The tag index page consist of all the tags with every post categorized under their tag/tags.
echo > "$tmp"/_tags.in.html

# For each tag, just append the previously generated list of posts HTML for that tag.
while read tag; do
	echo " Tag: $tag"
	echo "<h2 id='$tag'><a href='__ROOT__/blog/tags/$tag'>$tag</a></h2>" >> "$tmp"/_tags.in.html
	echo "<ul>" >> "$tmp"/_tags.in.html
	cat "$tmp/_tag_$tag.html" >> "$tmp"/_tags.in.html
	echo "</ul>" >> "$tmp"/_tags.in.html

	(replacefile "__ITEMS__" "$tmp/_tag_$tag.html" | replacetext __NUM_POSTS__ "$(wc -l "$tmp/_tag_$tag.html" | cut -d' ' -f1)" | replacetext __TAG__ "$tag" | commonreplace ../..) < templates/tag.in.html > blog/tags/"$tag".html &
	(replacefile "__FEED_" "$tmp/_tag_feed_$tag.xml" | replacetext __TAG__ "$tag" | commonreplace ../..) < templates/tag_feed.in.xml > blog/tags/"$tag.feed.xml" &
done < <(echo "$alltags" | xargs -n1 --no-run-if-empty)

echo " Waiting..."
wait

# Generate the full tag index page.
(replacefile "__TAGS__" "$tmp/_tags.in.html" | replacetext __NUM_TAGS__ "$(echo "$alltags" | wc -w)" | commonreplace ../..) < templates/tags.in.html > blog/tags/index.html

echo "Generating RSS feed..."
(replacefile "__FEED__" "$tmp/_feed.in.xml" | commonreplace ..) < templates/feed.in.xml > blog/feed.xml

echo "Processing images..."
for ext in jpg png; do
	find images -name "*.$ext" -prune | while read n; do
		n="$(basename "$n")"
		echo " Processing $n"
		convert -resize 10% -strip "images/$n" "thumbs/${n%.*}.10.$ext" &
		convert -resize 25% -strip "images/$n" "thumbs/${n%.*}.25.$ext" &
		convert -resize 50% -strip "images/$n" "thumbs/${n%.*}.50.$ext" &
	done
done

echo " Waiting..."
wait
