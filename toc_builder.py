#!/usr/bin/env python3
import sys
import lxml.html
from lxml.html import builder as E

def insert_headers(parent, headers):
	for header in headers:
		li = E.LI()
		parent.append(li)

		if "id" in header["element"].keys():
			link = E.A(header["element"].text_content(), href=("#" + header["element"].get("id")))
			li.append(link)
		else:
			li.append(E.SPAN(header["element"].text_content()))

		if header["headers"]:
			sub_list = lxml.html.Element(parent.tag)
			li.append(sub_list)
			insert_headers(sub_list, header["headers"])

def all(element):
	yield element
	for child in element:
		yield from all(child)

header_tags = ["h2", "h3", "h4", "h5", "h6"]

if __name__ == "__main__":
	html_tree = lxml.html.parse(sys.stdin)
	html = html_tree.getroot()
	headers = []

	def find_next_headers(i, starti=0, headers=headers):
		if i == starti:
			return headers
		else:
			return find_next_headers(i, starti=(starti + 1), headers=headers[-1]["headers"])

	for element in all(html):
		def n():
			return {
				"element": element,
				"headers": [],
			}

		if element.tag in header_tags:
			selfi = header_tags.index(element.tag)
			find_next_headers(selfi).append(n())

	for toc in html.find_class("toc"):
		insert_headers(toc, headers)

	sys.stdout.write(lxml.html.tostring(html_tree).decode())
