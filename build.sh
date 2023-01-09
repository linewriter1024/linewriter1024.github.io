#!/bin/bash

echo "Akas..."

while read line; do
	name="$(echo "$line" | cut -d' ' -f1)"
	url="$(echo "$line" | cut -d' ' -f2-)"

	file="aka/$name.html"

	echo "<!DOCTYPE html>" > $file
	echo "<title>Redirecting to $url</title>" >> $file
	echo "<meta http-equiv='refresh' content='0; URL=$url'>" >> $file
	echo '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />' >> $file
	echo '<meta http-equiv="Pragma" content="no-cache" />' >> $file
	echo '<meta http-equiv="Expires" content="0" />' >> $file
	echo "<link rel='canonical' href='https://mapper1024.github.io'>" >> $file
	echo "Redirecting to <a href='$url'>$url</a>..." >> $file

	echo " Wrote $name -> $url"
done < akas.txt

alltags=""

post() {
	name="$1"
	title="$2"
	date="$3"
	tags="$4"

	infile="blog.in/$name.in.html"
	outfile="blog/$name.html"

	echo " $name: $title [$date]"

	taghtml=""
	smalltaghtml=""
	minortaghtml=""

	while read tag; do
		taghtml="$taghtml <a class='tag' href='tags#$tag'>#$tag</a>"
		minortaghtml="$minortaghtml <a class='smalltag' href='blog/tags#$tag'>#$tag</a>"
		smalltaghtml="$smalltaghtml <a class='smalltag' href='tags#$tag'>#$tag</a>"

		if ! echo "$alltags" | grep -w "$tag" > /dev/null; then
			echo " New tag: $tag"
			rm -f "blog/_tag_$tag.html"
		fi

	done < <(echo "$tags" | xargs -n1)

	while read tag; do
		echo "<li class='postlisting'><a href='$name'>$title</a> [$date] $smalltaghtml</li>" >> "blog/_tag_$tag.html"
	done < <(echo "$tags" | xargs -n1)

	BN=$((BN+1))

	if [ $BN -le 3 ]; then
		echo "<li class='postlisting'><a href='blog/$name'>$title</a> [$date] $minortaghtml</li>" >> blog/_minor.in.html
	fi

	echo "<li class='postlisting'><a href='$name'>$title</a> [$date] $smalltaghtml</li>" >> blog/_major.in.html

	alltags="$alltags $tags"

	(sed "s^__TITLE__^$title^" | sed "s^__DATE__^$date^" | sed "s^__TAGS__^$taghtml^" | sed -e "/__POST__/r$infile" | sed 's/__POST__//g') < templates/post.in.html > "$outfile"
}

BN=0

echo "Blog..."

echo "<ul>" > blog/_major.in.html
echo "<ul>" > blog/_minor.in.html

source blog.in/posts.sh

echo "</ul>" >> blog/_major.in.html
echo "<li><a href='blog'>More...</a></li></ul>" >> blog/_minor.in.html

(sed -e '/__BLOGMINOR__/rblog/_minor.in.html' | sed 's/__BLOGMINOR__//g') < templates/index.in.html > index.html

(sed -e '/__BLOGMAJOR__/rblog/_major.in.html' | sed 's/__BLOGMAJOR__//g') < templates/blog.in.html > blog/index.html


alltags="$(echo "$alltags" | xargs -n1 | sort | uniq | xargs)"

echo > blog/_tags.in.html

while read tag; do
	echo "<h1>$tag</h1>" >> blog/_tags.in.html
	echo "<ul>" >> blog/_tags.in.html
	cat "blog/_tag_$tag.html" >> blog/_tags.in.html
	echo "</ul>" >> blog/_tags.in.html
done < <(echo "$alltags" | xargs -n1)

(sed -e '/__TAGS__/rblog/_tags.in.html' | sed 's/__TAGS__//g') < templates/tags.in.html > blog/tags.html
