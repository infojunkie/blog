---
layout: post
title: Documenting the MusicXML schema
date: 2020-12-06
---
{% include changelog.html changes="Dec 8, 2020 | Community Group update" %}

The [latest MusicXML version is 3.1](https://w3c.github.io/musicxml/). However, the [official MusicXML documentation stops at version 3.0](http://usermanuals.musicxml.com/MusicXML/MusicXML.htm), and the Music Notation Community Group's plan to keep the documentation updated is unclear.

<!--more-->

So I decided to spend some time researching existing tools to convert MusicXML's [schema definition (XSD)](https://en.wikipedia.org/wiki/XML_Schema_(W3C)) to HTML, and hit upon [`xs3p`](https://github.com/Mapudo/xs3p), which has a venerable lineage going back several years and multiple incarnations. Since XSD is itself expressed as XML, the simplest approach (and the one adopted by `xs3p`) is to produce an [XSLT script](https://developer.mozilla.org/en-US/docs/Web/XSLT) that transforms the schema definition into HTML.

Using the standard [`xsltproc` console tool](http://xmlsoft.org/XSLT/), I simply ran:
```
xsltproc /path/to/xs3p/xs3p.xsl /path/to/musicxml-3.1/schema/musicxml.xsd > musicxml.html
```
and obtained [an HTML version of the full MusicXML schema definition]({% link /musicxml.html %}) in no time flat! :tada:

## Pros
- One-line transformation process means easy automation
- Single HTML file means no search engine needed - browser page search is enough
- Single HTML file means easy packaging and hosting
- HTML5 / UTF-8 / Markdown / Bootstrap support means better documentation output

## Cons
- Large HTML file means slower browser response
- Not responsive on smaller form factors
- Left-side navigation pane scrolling is tied to main content scrolling

If there's interest from the [W3C Music Notation Community Group](https://www.w3.org/community/music-notation/), I will consider working on some fixes to enhance the HTML output :crossed_fingers:

## Update Dec 8, 2020
The W3C MusicXML Community Group is ready to move ahead with a new documentation site! [The discussion is happening here](https://github.com/w3c/musicxml/issues/353) - they were gracious enough to mention my modest experiment :heart_eyes:
