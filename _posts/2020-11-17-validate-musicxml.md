---
layout: post
title: Validating MusicXML files without the tears
date: 2020-11-17
---
MusicXML is a standard open format for exchanging digital sheet music, supported by [a large number of music applications](https://www.musicxml.com/software/). Version 3.1 is the first version to be released by the [W3C Music Notation Community Group](https://www.w3.org/community/music-notation/).

It's a complex format, aiming at capturing both presentation and playback information for a piece of music. That makes it tricky to parse, and tricky to generate. This short note presents a recipe to easily validate MusicXML 3.1 files using open source tools.

## MusicXML validation on the console

MusicXML ships with XSD and DTD files that describe the document structure. We can use the widely-supported tool `xmllint` (included in [libxml2](http://www.xmlsoft.org/) on most platforms) to validate MusicXML files against the official XSD. As always, a bit of fiddling is needed to get things right :sweat_smile:

First, download and extract the [latest MusicXML package from W3C's GitHub](https://github.com/w3c/musicxml/releases). Because the current XSD contains invalid `xs:import` links, it is necessary to [apply a patch](https://github.com/w3c/musicxml/pull/284) before proceeding with validation. The patch is very simple; you need to change:
```
<xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="http://www.musicxml.org/xsd/xml.xsd"/>
<xs:import namespace="http://www.w3.org/1999/xlink" schemaLocation="http://www.musicxml.org/xsd/xlink.xsd"/>
```
to refer to correct locations, either `w3.org`:
```
<xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="http://www.w3.org/2001/xml.xsd"/>
<xs:import namespace="http://www.w3.org/1999/xlink" schemaLocation="http://www.w3.org/1999/xlink.xsd"/>
```
or, since the MusicXML package ships with those files, simply:
```
<xs:import namespace="http://www.w3.org/XML/1998/namespace" schemaLocation="xml.xsd"/>
<xs:import namespace="http://www.w3.org/1999/xlink" schemaLocation="xlink.xsd"/>
```

You are now ready to use `xmllint` to validate your MusicXML files:
```
$ xmllint --schema musicxml-3.1/schema/musicxml.xsd valid.musicxml --noout
valid.musicxml validates
$ xmllint --schema musicxml-3.1/schema/musicxml.xsd invalid.musicxml --noout
invalid.musicxml:3: element score-partwise: Schemas validity error : Element 'score-partwise', attribute 'bad-attribute': The attribute 'bad-attribute' is not allowed.
invalid.musicxml fails to validate
```

The difference between local and external links to `xml.xsd` and `xlink.xsd` is twofold:
- The time taken for validation is significant. For local files:

```
$ time xmllint --schema musicxml-3.1/schema/musicxml.xsd valid.musicxml --noout
valid.musicxml validates

real	0m0.043s
user	0m0.038s
sys	0m0.005s
```
whereas for external files, it takes 15 _seconds_:

```
$ time xmllint --schema musicxml-3.1/schema/musicxml.xsd valid.musicxml --noout
valid.musicxml validates

real	0m15.478s
user	0m0.038s
sys	0m0.005s
```
- Secondly, in some environments, it may be necessary to run without an Internet connection, i.e `xmllint --nonet`. Here's what happens in this case:

```
$ xmllint --schema musicxml-3.1/schema/musicxml.xsd valid.musicxml --noout --nonet
valid.musicxml validates
```
versus

```
$ xmllint --schema musicxml-3.1/schema/musicxml.xsd valid.musicxml --noout --nonet
I/O error : Attempt to load network entity http://www.w3.org/2001/xml.xsd
warning: failed to load external entity "http://www.w3.org/2001/xml.xsd"
musicxml-3.1/schema/musicxml.xsd:24: element import: Schemas parser warning : Element '{http://www.w3.org/2001/XMLSchema}import': Failed to locate a schema at location 'http://www.w3.org/2001/xml.xsd'. Skipping the import.
I/O error : Attempt to load network entity http://www.w3.org/1999/xlink.xsd
warning: failed to load external entity "http://www.w3.org/1999/xlink.xsd"
musicxml-3.1/schema/musicxml.xsd:25: element import: Schemas parser warning : Element '{http://www.w3.org/2001/XMLSchema}import': Failed to locate a schema at location 'http://www.w3.org/1999/xlink.xsd'. Skipping the import.
[..]
WXS schema musicxml-3.1/schema/musicxml.xsd failed to compile
```

## MusicXML validation programmatically
If you application exports MusicXML files, it's a good idea to validate them before processing, to avoid tripping your code or exporting invalid files. On my [iReal Pro to MusicXML converter](https://github.com/infojunkie/ireal-musicxml), I use the JavaScript module [validate-with-xmllint](https://www.npmjs.com/package/validate-with-xmllint) in the tests to ensure that the converter module generates valid MusicXML. Since this needs to run at build time, and not on production, I only [need to install `xmllint` on the CI server](https://github.com/infojunkie/ireal-musicxml/blob/c9a08554675efc7eb5be6b0d02243abc19a95afd/.github/workflows/test.yml#L16).

But XSD validation is not enough to ensure that your generated XML is valid _semantically_. It is also necessary to ensure that the expected elements are present, and contain the right values. For this, you need to reach inside your generated XML and compare generated values with your expectations. The easiest and most maintainable way I've found for that is using [XPath, the XML query language](https://developer.mozilla.org/en-US/docs/Web/XPath). For this, I use [`xmldom`](https://www.npmjs.com/package/xmldom) and [`xpath.js`](https://www.npmjs.com/package/xpath.js) to [validate the generated MusicXML files during the test phase](https://github.com/infojunkie/ireal-musicxml/blob/f915531d2b8abef62beebdf72cacde7d555c4f54/test/musicxml.spec.js#L40-L57).

That's it! Hope you find this useful :raised_hands:
