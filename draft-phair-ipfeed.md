---
title: "ipfeed: Self-Published IP Network Metadata Format"
abbrev: "ipfeed"
category: info
submissiontype: independent

docname: draft-phair-ipfeed-latest
ipr: trust200902
area: ops
keyword:
  - geolocation
  - geofeed
  - IP metadata
  - CSV
  - self-published

stand_alone: yes
smart_quotes: no
pi: [toc, sortrefs, symrefs]

author:
  - fullname: Kevin Phair
    initials: K.
    surname: Phair
    organization: MaxMind
    email: kphair@maxmind.com

normative:
  RFC2119:
  RFC4180:
  RFC8174:
  RFC9632:

informative:
  RFC8805:
  RFC6888:
  I-D.ietf-opsawg-prefix-lengths:

--- abstract

This document defines ipfeed, a CSV-based format for self-publishing IP
network metadata. Network operators, cloud providers, enterprises, and
other IP address space managers use ipfeed to publish structured
information about their IP prefixes --- including location, network
classification, and arbitrary custom data.

ipfeed extends the RFC 8805 geofeed format with a metadata line, an
explicit column header, richer field support, and null semantics. Where
geofeeds provide five fixed columns of location data, ipfeed allows
producers to publish any combination of common and custom fields while
retaining the simplicity and universal tooling support of CSV.

--- middle

# Introduction

ipfeed is a CSV-based format for self-publishing IP network metadata.
Network operators, cloud providers, enterprises, and other IP address
space managers use ipfeed to publish structured information about their
IP prefixes --- including location, network classification, and
arbitrary custom data.

ipfeed extends the RFC 8805 geofeed format {{RFC8805}} with a metadata
line, an explicit column header, richer field support, and null
semantics. Where geofeeds provide five fixed columns of location data,
ipfeed allows producers to publish any combination of common and custom
fields while retaining the simplicity and universal tooling support of
CSV.

## Design Goals

Simplicity:
: CSV is supported everywhere --- spreadsheets, command-line tools,
  scripting languages, and databases can all read and write it without
  special libraries.

Data richness:
: Producers can publish any metadata they have about their prefixes, not
  just location.

Extensibility:
: Producers add columns freely. Consumers ignore what they don't
  recognize. No coordination required to extend.

Familiarity:
: Existing geofeed publishers already work with CSV. An ipfeed looks and
  feels like a geofeed with more columns.

## Relationship to RFC 8805

ipfeed is an evolution of RFC 8805 geofeeds {{RFC8805}}. It adds the
structure that geofeeds lack --- metadata, explicit column headers,
extensibility, and null semantics --- while keeping the CSV simplicity
that made geofeeds successful.

| Feature | RFC 8805 Geofeed | ipfeed |
|---|---|---|
| Format | CSV (5 fixed columns) | CSV (flexible columns) |
| Column header | None (implicit) | Explicit (line 2) |
| Metadata | Comment lines | Structured metadata line |
| Data scope | Location only | Any IP metadata |
| Extensibility | None | Custom columns |
| Null semantics | Empty = no data | Empty = no data, `\N` = retraction |
| Library requirements | CSV parser | CSV parser |

Existing geofeeds can be upgraded to ipfeed by prepending a metadata
line and a column header (see {{geofeed-conversion}}). Other efforts to
extend the geofeed ecosystem include {{I-D.ietf-opsawg-prefix-lengths}},
which defines a companion format for publishing expected prefix lengths.

# Terminology

{::boilerplate bcp14-tagged}

Producer:
: An entity that creates and publishes an ipfeed file.

Consumer:
: An entity that retrieves and processes an ipfeed file.

Metadata line:
: The first line of an ipfeed file, a `#`-prefixed line containing the
  `ipfeed_version` key and other key-value pairs that describe the feed.

Comment line:
: A `#`-prefixed line that is not the metadata line. Comment lines carry
  no structured semantics and may appear anywhere in the file.

Column header:
: The first non-blank, non-comment line after the metadata line, listing
  the field names for all subsequent data rows.

Data row:
: A non-blank, non-comment CSV row after the column header, containing
  metadata for a single network prefix.

Common field:
: A field name with defined semantics in this specification
  ({{common-fields}}). Also referred to as a "well-known field."

Extension field:
: A field name not defined in this specification, added by a producer
  for their own purposes.

# File Format

## Encoding

An ipfeed file MUST be encoded in UTF-8. A UTF-8 byte order mark (BOM,
U+FEFF) at the start of the file is OPTIONAL; consumers MUST accept
files with or without a BOM. Data rows MUST conform to {{RFC4180}}
(Common Format and MIME Type for Comma-Separated Values). Lines MUST be
terminated by a newline character (LF, U+000A) or a carriage return
followed by a newline (CRLF, U+000D U+000A).

## Structure

An ipfeed file consists of the following parts, in order:

1. **Metadata line** (REQUIRED) --- the first line of the file
2. **Column header** (REQUIRED) --- the first non-blank, non-comment
   line after the metadata line
3. **Data rows** --- zero or more CSV rows

Comment lines (beginning with `#`) and blank lines MAY appear anywhere
after the metadata line. Consumers MUST skip comment lines and blank
lines when processing. The metadata line is distinguished from other
comment lines by containing the `ipfeed_version` key (see
{{metadata-line}}).

## Metadata Line

The metadata line MUST be the first line of the file (or the first line
after a UTF-8 BOM, if present). It MUST begin with the `#` character,
followed by a space, followed by one or more semicolon-separated
`key=value` pairs. It is identified by the presence of the
`ipfeed_version` key.

~~~
# ipfeed_version=1; publisher=AS64496; publisher_name=Example ISP; generated=2026-02-11T00:00:00Z
~~~

### Syntax

~~~abnf
metadata_line  = "#" SP pair *( ";" SP pair )
pair           = key "=" value
key            = 1*( ALPHA / DIGIT / "_" )
value          = plain_value / quoted_value
plain_value    = *( any character except ";" and "=" and DQUOTE )
quoted_value   = DQUOTE *( any character / DQUOTE DQUOTE ) DQUOTE
~~~

Values that contain semicolons (`;`), equals signs (`=`), or double
quotes (`"`) MUST be enclosed in double quotes. Within a quoted value, a
literal double quote is represented as two consecutive double quotes
(`""`), following {{RFC4180}} quoting conventions.

Leading and trailing whitespace in values SHOULD be trimmed by consumers
unless the value is quoted.

### Metadata Fields

| Field | Required | Description |
|---|---|---|
| `ipfeed_version` | REQUIRED | Format version. MUST be `1` for this specification. See {{version-compatibility}}. |
| `publisher` | RECOMMENDED | Publisher identifier (e.g., ASN like `AS64496`, domain, or organization name). |
| `publisher_name` | OPTIONAL | Human-readable name of the publisher. |
| `generated` | RECOMMENDED | ISO 8601 timestamp indicating when this file was generated. See {{generated-semantics}}. |
| `contact_email` | OPTIONAL | Contact email address for the publisher. |
| `url` | OPTIONAL | Canonical URL where this ipfeed is published. |

Consumers MUST ignore unrecognized metadata keys.

### Version Compatibility {#version-compatibility}

The `ipfeed_version` field carries a single positive integer. Each
integer value is defined by a distinct specification document; this
document defines `ipfeed_version=1`. Because every version is its own
published document, version increments are expected to be rare and to
correspond to changes substantial enough to warrant a new RFC.

Producers MUST set `ipfeed_version` to the integer value of the
specification they actually implement, never to a higher value they
merely intend to support.

Consumers behave as follows on encountering an `ipfeed_version` value:

* If the value matches a version the consumer implements, the consumer
  MUST process the file according to that version's rules. Unknown
  common fields and unknown registered values for fields such as
  `user_type` or `connection_type` MUST be treated as unrecognized
  extension fields per {{extension-mechanism}}; this is the mechanism
  by which a single version of the specification accommodates evolving
  vocabulary.
* If the value is greater than any version the consumer implements,
  the consumer SHOULD reject the file rather than attempt best-effort
  parsing, because the file's structural meaning is unspecified to it.
* If the value is lower than any version the consumer implements, the
  consumer MAY process the file using the older version's rules,
  provided the consumer still supports that version. Successor
  specifications will state explicitly whether and how they retain
  compatibility with files at lower `ipfeed_version` values.

### `generated` Timestamp Semantics {#generated-semantics}

The `generated` field records the moment at which the producer serialized
this particular file, not the freshness of the underlying data. Producers
SHOULD update `generated` on every regenerated file --- including
regenerations whose row content is unchanged --- so that consumers can
distinguish "successfully refreshed, no changes" from "stale; the producer
is no longer publishing."

Producers MUST NOT use `generated` to advertise data freshness in a way
that contradicts the file's actual contents (e.g., setting it to a future
time, or holding it constant across regenerations to imply the data is
"current"). Consumers MAY use `generated` together with HTTP response
metadata to detect a stalled producer, but SHOULD NOT treat a recent
`generated` value as evidence that any individual row has been recently
verified; per-row freshness is conveyed by `last_verified`
({{common-fields}}).

## Column Header

The column header is the first non-blank, non-comment line after the
metadata line. It is a comma-separated list of field names, one for each
column in the subsequent data rows.

~~~
network,country,region,city,user_type,connection_type,is_anycast
~~~

The column `network` MUST be present and MUST be the first column. All
other columns are OPTIONAL and may appear in any order.

Column names MUST consist of lowercase ASCII letters, digits, and
underscores. Column names MUST NOT be empty.

Consumers MUST ignore columns whose names they do not recognize. This
ensures forward compatibility --- producers can add new columns without
breaking existing consumers.

## Data Rows

Each data row represents one network prefix. Fields are separated by
commas, with quoting per {{RFC4180}}. The number of fields in each data
row MUST match the number of columns in the column header.

The `network` field (first column) is REQUIRED in every data row. It
MUST contain an IP address prefix in CIDR notation (e.g.,
`203.0.113.0/24` or `2001:db8::/32`). Both IPv4 and IPv6 prefixes are
supported.

## Ordering

Data rows MAY appear in any order. Consumers MUST NOT depend on the
ordering of rows within a file.

## Overlapping Prefixes

A file MAY contain overlapping prefixes (e.g., both `192.0.2.0/24` and
`192.0.2.0/28`). When prefixes overlap, consumers SHOULD apply
most-specific-match semantics (longest prefix match), consistent with IP
routing conventions.

# Common Fields {#common-fields}

The following fields have defined semantics. Producers SHOULD use these
field names when their data matches the described semantics, to maximize
interoperability.

All common fields are OPTIONAL --- a producer includes only the columns
relevant to the data they have. The only required column is `network`.

## Location Fields

| Field | Type | Description |
|---|---|---|
| `country` | string | ISO 3166-1 alpha-2 country code (e.g., `US`, `DE`, `JP`). |
| `region` | string | ISO 3166-2 subdivision code (e.g., `US-CA`, `DE-BY`). |
| `city` | string | City, town, village, or other locality name in UTF-8. |

## Network Classification Fields

| Field | Type | Description |
|---|---|---|
| `isp` | string | Internet Service Provider name. |
| `organization` | string | Organization name associated with the prefix. |
| `user_type` | string | How the network is used. See {{registered-user_type-values}} for registered values. |
| `connection_type` | string | Physical connection technology. See {{registered-connection_type-values}} for registered values. |
| `domain` | string | Domain name of the network operator. |
| `is_anycast` | boolean | `true` if the prefix is used for anycast routing. |
| `is_proxy` | boolean | `true` if the prefix is known to be used for proxy or VPN services. |
| `is_cgnat` | boolean | `true` if the prefix is behind Carrier-Grade NAT {{RFC6888}}. |

## Data Quality Fields

| Field | Type | Description |
|---|---|---|
| `confidence_value` | number | Producer's confidence in this record, from `0` (no confidence) to `100` (fully confident). |
| `last_verified` | string | ISO 8601 timestamp indicating when this record was last verified by the producer. |

## Registered `user_type` Values {#registered-user_type-values}

The `user_type` field describes the logical use of a network --- who or
what is using the address space.

| Value | Description |
|---|---|
| `residential` | Residential broadband users. |
| `business` | Business or commercial internet service. |
| `hosting` | Hosting, cloud, or data center infrastructure. |
| `cellular` | Mobile/cellular network users. |
| `enterprise` | Enterprise or corporate network. |
| `education` | Educational institution network. |
| `government` | Government network. |
| `satellite` | Satellite internet users. |
| `ai_agent` | Serving AI agent traffic. |

## Registered `connection_type` Values {#registered-connection_type-values}

The `connection_type` field describes the physical connection technology
used to deliver network service.

| Value | Description |
|---|---|
| `cable_dsl` | Cable modem or DSL connection. |
| `cellular` | Mobile/cellular radio connection. |
| `satellite` | Satellite link. |
| `fiber` | Fiber-optic connection. |
| `cellular_broadband` | Fixed wireless broadband using cellular technology. |

Additional values MAY be defined in future versions of this
specification.

## Column Naming Conventions

Field names follow conventions that indicate their data type:

| Convention | Type | Examples |
|---|---|---|
| `is_*` | boolean | `is_anycast`, `is_proxy` |
| `*_value` | number | `confidence_value` |
| All other names | string | `country`, `city`, `user_type` |

Boolean fields MUST use the lowercase values `true` or `false`. Producers
MUST NOT use `True`, `TRUE`, `1`, `yes`, or any other casing or synonym.
Consumers MAY accept other casings out of robustness, but SHOULD report
non-conforming values to the publisher. An empty boolean field means the
producer has no data (see {{null-semantics}}); a `\N` value is a positive
retraction (see {{null-semantics}}).

Numeric fields contain decimal numbers. An empty numeric field means the
producer has no data (see {{null-semantics}}).

# Null Semantics {#null-semantics}

CSV fields have three meaningful states:

| State | CSV representation | Meaning |
|---|---|---|
| Value present | `Auckland` | The producer provides this value. |
| No data | (empty: `,,`) | The producer has no data for this field. They didn't check, don't know, or it isn't applicable for this row. |
| Retraction | `\N` | The producer explicitly asserts that consumers should discard any existing data for this field. |

The distinction between "no data" and "retraction" matters for consumers
that merge data from multiple sources. When a field is empty, the
consumer can fall back to other data sources. When a field contains `\N`,
the producer is actively saying "this field should be blank" --- a
positive assertion that overrides other sources.

## Examples

~~~
# ipfeed_version=1; publisher=AS64497
network,country,region,city,connection_type
203.0.113.0/24,NZ,,Auckland,fiber
198.51.100.0/24,US,US-WY,\N,satellite
~~~

In the first data row, `region` is empty --- the producer has no region
data for this network, and consumers may use other sources.

In the second data row, `city` is `\N` --- the producer has determined
that there is no meaningful city for this satellite network and asserts
that consumers should discard any city they might have from other
sources.

## Guidance

Producers SHOULD use empty fields (no data) as the default when they
lack information. The `\N` sentinel SHOULD be reserved for intentional
retraction --- cases where the producer has checked and determined that
no value is correct.

# Extension Mechanism

Any column in the column header that is not a common field
({{common-fields}}) is a **custom extension field**. Consumers MUST
silently ignore columns they do not recognize. This ensures forward
compatibility --- producers can add new columns without breaking existing
consumers.

## Declaring Extension Fields

Extension fields are declared simply by including them in the column
header. No registration or coordination is required. The following
examples show column headers and data rows only (the metadata line is
omitted for brevity):

~~~
network,country,city,cloud_region,cloud_service
198.51.100.0/24,US,Sometown,region-east-1,compute
~~~

## Naming Conventions

Extension field names SHOULD:

* Use lowercase letters, digits, and underscores
* Follow the type conventions in {{column-naming-conventions}}
  (`is_*` for booleans, `*_value` for numbers)
* Be descriptive enough that their purpose is clear without external
  documentation

## Examples

**Cloud provider publishing region metadata:**

~~~
network,country,connection_type,organization,cloud_region,cloud_service
198.51.100.0/24,US,hosting,Example Cloud,region-east-1,compute
198.51.101.0/24,KR,hosting,Example Cloud,region-apac-3,compute
~~~

**ISP publishing internal network identifiers:**

~~~
network,country,connection_type,user_type,isp,internal_node_id,speed_tier
203.0.113.0/24,US,,residential,Example Cable,DAL-42,gigabit
~~~

If a custom field becomes widely used across multiple producers, it MAY
be proposed for inclusion in the common field set in a future version of
this specification.

# Geofeed Conversion {#geofeed-conversion}

An RFC 8805 geofeed {{RFC8805}} can be upgraded to ipfeed with minimal
changes:

1. **Prepend a metadata line** with at least `ipfeed_version=1`.
2. **Add a column header**: `network,country,region,city,postal_code`
3. **Existing data rows work as-is.** The five geofeed columns map
   directly to ipfeed columns.

Note that `postal_code` is not a common ipfeed field but is preserved
during conversion to avoid data loss. Consumers that do not recognize
`postal_code` will silently ignore it.

## Field Mapping

| Geofeed column (position) | ipfeed column |
|---|---|
| 1 (IP prefix) | `network` |
| 2 (Country) | `country` |
| 3 (Region) | `region` |
| 4 (City) | `city` |
| 5 (Postal code) | `postal_code` |

## Conversion Rules

1. Each non-comment, non-empty geofeed line becomes one data row.
2. Empty geofeed fields become empty ipfeed fields (not `\N`), because a
   geofeed producer has not positively asserted "no value" --- they
   simply did not provide data.
3. Comment lines (`#`) are discarded. Relevant metadata (publisher info,
   contact_email, URL) SHOULD be placed in the metadata line.
4. Geofeed `# entry` RPKI signature lines are discarded during
   conversion.

## Example

**Original geofeed:**

~~~
# Geofeed for AS64496
203.0.113.0/24,NZ,,Auckland,
203.0.114.0/24,NZ,,Wellington,6011
~~~

**Converted ipfeed:**

~~~
# ipfeed_version=1; publisher=AS64496
network,country,region,city,postal_code
203.0.113.0/24,NZ,,Auckland,
203.0.114.0/24,NZ,,Wellington,6011
~~~

# Publication and Discovery

## File Extension

The RECOMMENDED file extension for ipfeed files is `.csv`. Where it is
useful to distinguish ipfeed files from generic CSV files (for example, in
a directory of mixed-purpose files), the extension `.ipfeed` MAY be used.

The metadata line ({{metadata-line}}) is the authoritative indicator that
a file is an ipfeed. Consumers MUST NOT rely on the file extension alone
to identify an ipfeed file.

## Media Type

The RECOMMENDED media type for ipfeed files is `text/csv` per {{RFC4180}}.
ipfeed does not register a distinct media type; the metadata line on the
first line of the file is sufficient for consumers to recognize the
format.

When ipfeed files are served over HTTP, producers SHOULD set the
`Content-Type` header to `text/csv; charset=utf-8`.

## Discovery

Producers SHOULD make their ipfeed file discoverable using the same
mechanism defined for RFC 8805 geofeeds in {{RFC9632}}: a `geofeed:`
attribute on the relevant `inetnum:` or `inet6num:` object in the RPSL
records of a Regional Internet Registry, whose value is the HTTPS URL of
the file.

Consumers that follow a `geofeed:` reference SHOULD detect the ipfeed
metadata line ({{metadata-line}}) and process the file as an ipfeed if
the line is present, falling back to RFC 8805 parsing otherwise.

Discovery mechanisms beyond RFC 9632 (for example, well-known URIs,
DNS-based pointers, or RDAP extensions) are out of scope for this
document.

# Operational Considerations

This section gives non-normative guidance for producers and consumers
deploying ipfeed in practice.

## File Size

ipfeed files describe a producer's address space at row-level
granularity, so file size grows with the number of distinct prefixes
and the number of populated columns. Producers SHOULD aim for files
small enough to be retrieved and parsed in a single HTTP exchange
without special tooling. As a soft target, files up to a few megabytes
are easily handled by typical consumers; files in the tens of
megabytes start to force consumers into streaming or chunked
processing and SHOULD be split or summarized where possible.

When a producer's data is too large for a single file, producers MAY
publish multiple ipfeed files (for example, partitioned by region or
ASN). Cross-file consistency, partitioning conventions, and
manifest/index mechanisms are out of scope for this document.

## Refresh Cadence

ipfeed publishes a producer's current view of their address space at
the moment the file was generated. The appropriate refresh cadence is
a producer choice driven by how quickly their underlying data changes;
there is no normative minimum or maximum.

Producers SHOULD regenerate and republish on a regular schedule even
when row data has not changed, so that consumers can distinguish
"actively maintained, no recent changes" from "abandoned." The
`generated` field ({{generated-semantics}}) carries the
last-regeneration timestamp.

Consumers SHOULD NOT poll faster than once per hour without prior
arrangement with the producer. Consumers SHOULD use HTTP conditional
requests (see {{http-caching}}) to avoid redundant transfers when the
file has not changed.

## HTTP Caching {#http-caching}

When ipfeed files are served over HTTP, both producers and consumers
SHOULD use standard HTTP cache controls to minimize transfer cost.

Producers SHOULD:

* Set a `Last-Modified` response header reflecting the file's
  `generated` time (or the underlying file modification time if it is
  later).
* Set a strong `ETag` derived from the file's content, so that
  unchanged regenerations of identical content return `304 Not
  Modified` on conditional fetches.
* Set a `Cache-Control` header consistent with the producer's refresh
  cadence (for example, `Cache-Control: max-age=3600` for an hourly
  feed).

Consumers SHOULD:

* Cache the most recent successful response and issue conditional
  requests using `If-Modified-Since` and `If-None-Match` on subsequent
  fetches.
* Respect the producer's `Cache-Control` directives as a lower bound
  on poll interval.
* Treat a `304 Not Modified` response as "no change since last fetch,"
  not as evidence of file generation freshness; the `generated`
  timestamp inside the file remains the authoritative source.

# Security Considerations

ipfeed files are self-published data. A producer can claim any metadata
for any prefix, whether or not they are the legitimate operator of that
address space. Consumers SHOULD NOT treat ipfeed data as authoritative
without independent verification.

Authentication and integrity mechanisms (such as RPKI-based signing or
RDAP linkage) are expected to be addressed in a companion
specification.

Consumers processing ipfeed files from untrusted sources SHOULD:

* Validate that `network` values are well-formed CIDR notation.
* Reject records with prefixes outside publicly routable address space
  unless specifically intended for private use.
* Apply rate limiting and size limits to prevent resource exhaustion from
  excessively large feeds.
* Sanitize string field values before use in contexts where injection is
  possible (e.g., SQL queries, HTML rendering).

## Transport

Producers SHOULD publish ipfeed files over HTTPS so that consumers can
verify channel integrity and authenticate the publishing endpoint.
Consumers SHOULD reject ipfeed URLs that resolve over plain HTTP except
in test or private-use contexts where the channel is trusted by other
means.

Producers SHOULD use stable URLs and avoid redirecting from `https://`
to `http://`. Consumers MUST NOT follow such downgrades automatically.

# IANA Considerations

This document has no IANA actions.

--- back

# Examples

## Minimal Feed

A simple feed with only location data:

~~~
# ipfeed_version=1; publisher=AS64496; publisher_name=Example ISP
network,country,city
203.0.113.0/24,NZ,Auckland
203.0.114.0/24,NZ,Wellington
~~~

## Cloud Provider Feed

A cloud provider publishing region-level metadata with custom extension
fields:

~~~
# ipfeed_version=1; publisher=AS64498; publisher_name=Example Cloud; generated=2026-02-11T00:00:00Z; contact_email=noc@cloud.example.com
network,country,region,city,connection_type,user_type,organization,is_anycast,cloud_region,cloud_service
192.0.2.0/24,US,US-IA,Sometown,,hosting,Example Cloud,,region-east-1,compute
192.0.2.128/25,KR,KR-28,Somecity,,hosting,Example Cloud,,region-apac-3,compute
198.51.100.0/24,SG,,,,,Example Cloud,true,region-apac-1,compute
~~~

## ISP with Connection Type and User Type

An ISP publishing both physical connection technology and logical network
usage:

~~~
# ipfeed_version=1; publisher=AS64499; publisher_name=Example Cable ISP; contact_email=geofeeds@isp.example.com
network,country,region,city,user_type,connection_type,isp,confidence_value
203.0.113.0/24,US,,,residential,cable_dsl,Example Cable,90
203.0.113.128/25,US,US-OR,Sometown,residential,cable_dsl,Example Cable,
203.0.113.192/26,US,US-CA,,residential,cable_dsl,Example Cable,85
~~~

## Enterprise Network

An enterprise publishing internal network structure with extension
fields:

~~~
# ipfeed_version=1; publisher=Example University; generated=2026-01-15T12:00:00Z
network,country,region,city,user_type,organization,is_proxy,department
192.0.2.0/24,US,US-MA,Cambridge,education,Example University,,Computer Science
192.0.2.128/25,US,US-MA,Cambridge,education,Example University,false,Library
~~~

## Retraction Usage

A satellite ISP that knows country and connection type but asserts that
city data should be discarded:

~~~
# ipfeed_version=1; publisher=AS64497; publisher_name=Example Satellite
network,country,region,city,user_type,connection_type
198.51.100.0/24,US,US-WY,\N,satellite,satellite
198.51.101.0/24,US,\N,\N,satellite,satellite
198.51.102.0/24,AU,,,satellite,satellite
~~~

* Row 1: `city` is `\N` --- the producer asserts there is no meaningful
  city. Consumers should discard any city data they have for this
  prefix.
* Row 2: Both `region` and `city` are `\N` --- the producer asserts
  that neither region nor city is meaningful for this mobile satellite
  prefix.
* Row 3: `region` and `city` are empty --- the producer simply doesn't
  have this data. Consumers may use other sources.

# Acknowledgments
{:numbered="false"}

The authors would like to thank the contributors to RFC 8805 whose work
on geofeeds provided the foundation for this specification.
