#!/usr/bin/env python3
import sys
import lxml.html
from lxml.html import builder as E

def insert_headers(ol, headers):
	for header in headers:
		li = E.LI()
		ol.append(li)

		if "id" in header["element"].keys():
			link = E.A(header["element"].text_content(), href=("#" + header["element"].get("id")))
			li.append(link)
		else:
			li.append(E.SPAN(header["element"].text_content()))

		if header["headers"]:
			ol = E.OL()
			li.append(ol)
			insert_headers(ol, header["headers"])

def all(element):
	yield element
	for child in element:
		yield from all(child)

header_tags = ["h2", "h3", "h4", "h5", "h6"]

if __name__ == "__main__":
	html = lxml.html.fromstring(sys.stdin.read())
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
		if toc.tag == "ol":
			insert_headers(toc, headers)

	sys.stdout.write(lxml.html.tostring(html).decode())
