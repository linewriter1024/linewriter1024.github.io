#!/usr/bin/env python3
import sys
import lxml.html
from lxml.html import builder as E

def all(element):
	yield element
	for child in element:
		yield from all(child)

def fix_path(path):
	base = sys.argv[1]
	if path.startswith("./") or path.startswith("../"):
		return base + "/" + path
	else:
		return path

if __name__ == "__main__":
	html = lxml.html.fromstring(sys.stdin.read())

	for element in all(html):
		if element.tag == "a":
			if "href" in element.keys():
				element.set("href", fix_path(element.get("href")))
		elif element.tag == "img":
			if "src" in element.keys():
				element.set("src", fix_path(element.get("src")))

	sys.stdout.write(lxml.html.tostring(html, pretty_print=True).decode())
