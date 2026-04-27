SHELL := /bin/bash
.PHONY: all html txt clean
.DELETE_ON_ERROR:

# Tool configuration
KRAMDOWN_RFC ?= kramdown-rfc
XML2RFC      ?= xml2rfc

# Discover drafts
drafts_md  := $(wildcard draft-*.md)
drafts_xml := $(drafts_md:.md=.xml)
drafts_html := $(drafts_md:.md=.html)
drafts_txt := $(drafts_md:.md=.txt)

all: html txt
html: $(drafts_html)
txt: $(drafts_txt)

# Markdown -> XML (kramdown-rfc produces v3, then normalize with xml2rfc --v2v3)
%.xml: %.md
	$(KRAMDOWN_RFC) --v3 < $< | $(XML2RFC) --v2v3 /dev/stdin -o $@

# XML -> HTML (uses xml2rfc built-in CSS per RFC 7992/7993)
%.html: %.xml
	$(XML2RFC) -q --html $< -o $@

# XML -> TXT
%.txt: %.xml
	$(XML2RFC) -q --text --no-pagination $< -o $@

clean:
	rm -f $(drafts_xml) $(drafts_html) $(drafts_txt)
