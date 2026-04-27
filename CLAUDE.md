# CLAUDE.md

## Project Overview

This repository contains the working draft of an IETF Internet-Draft defining
**ipfeed**, a CSV-based format for self-publishing IP network metadata. ipfeed
extends RFC 8805 geofeeds with a metadata line, explicit column headers, richer
field support, and null semantics.

The specification document is `draft-phair-ipfeed.md`.

## Building the Draft

The build uses two tools directly — no external build framework:

```bash
bundle install          # Install kramdown-rfc (Ruby gem)
pip install xml2rfc     # Install xml2rfc (Python package)
make                    # Build HTML and TXT outputs
```

**Prerequisites**:
- Ruby (with Bundler)
- Python 3.10+

The build chain: `kramdown-rfc --v3` converts the markdown source to RFC XML,
then `xml2rfc` renders HTML and plain text outputs.

## Source Format

The draft is written in **kramdown-rfc** markdown. Key structural elements:

- **YAML front matter**: RFC metadata — title, authors, normative/informative
  references, document attributes
- **`--- abstract`** / **`--- middle`** / **`--- back`**: Standard RFC document
  sections
- **`{{RFC8805}}`**: Reference citations (resolved from the YAML `normative:`
  and `informative:` blocks)
- **`{#section-id}`**: Cross-reference anchors
- **`{::boilerplate bcp14-tagged}`**: Auto-generated BCP 14 boilerplate
- **`~~~` / `~~~abnf`**: Code blocks, optionally with syntax type

## Conventions

When editing the draft, follow these conventions:

- **RFC 2119/8174 keywords**: Use MUST, SHOULD, MAY, etc. with their formal
  meanings. These are auto-tagged via the BCP 14 boilerplate.
- **ABNF**: Use Augmented Backus-Naur Form for syntax definitions.
- **Example IP addresses**: Use RFC 5737 documentation ranges only
  (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24) and RFC 3849 for IPv6
  (2001:db8::/32).
- **Example ASNs**: Use RFC 5398 documentation range (AS64496-AS64511,
  AS65536-AS65551).
- **Example organizations**: Use fictional names (e.g., "Example ISP",
  "Example Cloud") rather than real companies.
