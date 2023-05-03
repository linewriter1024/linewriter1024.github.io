#!/usr/bin/env python3
import sys
import lxml.html

if __name__ == "__main__":
	html_tree = lxml.html.parse(sys.stdin)
	html = html_tree.getroot()

	i = 0

	for toc in html.find_class("alternate"):
		toc.classes.add("left" if (i % 2) == 0 else "right")
		i = i + 1

	sys.stdout.write(lxml.html.tostring(html_tree).decode())
