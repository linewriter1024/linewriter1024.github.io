#!/usr/bin/env python3
import sys
import lxml.html
import copy
from lxml.html import builder as E

def all(element):
	yield element
	for child in element:
		yield from all(child)

if __name__ == "__main__":
	html_tree = lxml.html.parse(sys.stdin)
	html = html_tree.getroot()

	copyfrom = {}

	for element in all(html):
		if "x-copy-id" in element.keys():
			copyfrom[element.get("x-copy-id")] = element

	for element in all(html):
		if "x-copy-from" in element.keys():
			copyfromid = element.get("x-copy-from")
			if copyfromid in copyfrom:
				element.getparent().replace(element, copy.deepcopy(copyfrom[copyfromid]))

	sys.stdout.write(lxml.html.tostring(html_tree).decode())
