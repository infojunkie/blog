---
layout: post
title: First release of iReal Pro to MusicXML converter
date: 2020-11-30
---
Yesterday, I finally published an [online demo of my iReal Pro to MusicXML converter](https://ethereum.karimratib.me:8082/), having spent around 300% of the time I had originally anticipated to reach the first release of this module. In this post, I hope to summarize the challenges, lessons learned, as well as the context around this work.

But first, some pretty pictures! Following is the same iReal Pro leadsheet, [Herbie Hancock's Butterfly](https://www.youtube.com/watch?v=knbmKDUYDXc), as rendered by iReal Pro, then rendered by [MuseScore](https://musescore.org/) and [OpenSheetMusicDisplay (OSMD)](https://opensheetmusicdisplay.github.io/), after MusicXML conversion. Click each thumbnail to see a larger image.

{% include image.html description="iReal Pro (source)" url="/assets/butterfly-ireal.png" %}
{% include image.html description="MuseScore (via MusicXML converter)" url="/assets/butterfly-musescore.png" %}
{% include image.html description="OSMD (via MusicXML converter)" url="/assets/butterfly-osmd.png" %}

## What's going on here?

For musicians, [iReal Pro](https://irealpro.com/) is an indispensable tool that captures the essence of practicing a tune. It allows to specify a full chord progression and to play it back in a number of styles, from pop to jazz to latin. Because the app is flexible and easy to use, it has attracted a [large community of users](https://irealb.com/forums/) who have contributed the [bulk of the leadsheets](https://irealpro.com/main-playlists/) that are in active use today. Now that's what I call a successful product! :pig:

For all its greatness, iReal Pro suffers from one big (but understandable) flaw: it is not open source. Philosophical considerations aside, this means that its development is gated and that fixes and new features are up to the whims and fortunes of a single organization. It's understandable, because how else could the app makers sustain their work by releasing their app in the open? [Open source business models are still contentious](https://news.ycombinator.com/item?id=25161220).

Still, some features of iReal Pro are frustrating, and there's always room for improvement. To me, the real value lies in the content, namely the thousands of royalty-free leadsheets that are community-driven, and therefore evolving with fixes and enhancements as they are being actively used. It is in this spirit that I decided to write a conversion module from the iReal Pro song format to the [standard music interchange format, MusicXML](https://www.w3.org/2017/12/musicxml31/).

## What's the point?

Although iReal Pro already features a MusicXML export function, the generated files refer to an obsolete version of the music standard, in addition to being non-compliant to its schema. [I've posted about MusicXML validation]({% post_url 2020-11-17-validate-musicxml %}) in the past, because it was an integral part of my development process. Further, the MusicXML export feature is only accessible via the app's UI and cannot be automated or batched.

The value of processing these leadsheets via a standard interchange format lies in the ability to rely on a wealth of [supporting applications](https://www.musicxml.com/software/) for further processing.

For example, one of my frustrations with iReal Pro, as a practicing musician, is that I _still_ need to refer to a traditional (Real Book) chart in order to read a song's melodic theme. During practice, I perform a complicated ritual on my tablet whereby I load up the PDF chart and the iReal Pro app, then click the Play button in Real Pro before quickly switching to the PDF chart while iReal Pro is counting in. Unnecessary pressure! It would be much more useful for an app to show both the full chart (including the melodic theme) _and_ to provide playback. A format like MusicXML is ideally suited for such an application.

## Building the module

Alright, enough justifications and let's jump into the technical aspects of this work. The main building blocks of the converter are:
- iReal Pro parser
- Intermediate representation builder
- MusicXML generator

### iReal Pro parser

Although the iReal Pro format is proprietary and officially undocumented, I was lucky enough to find previous work and functioning code to parse it. I mainly [copy/pasted code from other repos with minimal changes](https://github.com/infojunkie/ireal-musicxml/blob/main/src/parser.js) and was up and running in no time. I then [documented the format as best as I could](https://github.com/infojunkie/ireal-musicxml/blob/main/doc/ireal.md). Yay open source!!

### MusicXML generator

I skipped the middle step because it's the fun part :wink: Instead of hand-generating an XML string, I used the excellent [`jstoxml`](https://www.npmjs.com/package/jstoxml) to convert a regular JavaScript object containing the MusicXML structure into XML. I also used [`validate-with-xmllint`](https://www.npmjs.com/package/validate-with-xmllint), [`xmldom`](https://www.npmjs.com/package/xmldom) and [`xpath.js`](https://www.npmjs.com/package/xpath.js) to validate the generated MusicXML files during the test phase. Yay open source!!

### Intermediate representation

This is where all the fun and domain-specific learning happened :musical_note: :tada: I faced several challenges here:
- Emitting correct chord information
- Emulating the iReal Pro playback model
- Ensuring compatibility with other software

### Emitting correct chord information

Chords are at the heart of a leadsheet. Chord notation is heavily based on convention, with [multiple alternate representations](https://en.wikipedia.org/wiki/Chord_letters) for the same chord depending on the application, musical style, etc. MusicXML defines a [`harmony` element](https://usermanuals.musicxml.com/MusicXML/Content/CT-MusicXML-harmony.htm) that represents a chord structure based on the following blocks:
- Chord root, as a note in the (Western 12-tone) scale
- Chord quality: major, minor, dominant 7th, major 7th, etc.
- Bass note, as in C/G
- The altered degrees, such as ♯5, ♭13, etc.
- More semantic elements such as chord function (tonic, dominant), inversion, etc. that I do not process at the moment.

I turned to the excellent module [`chord-symbol`](https://github.com/no-chris/chord-symbol) to provide chord parsing and structural analysis. This module is built upon a [solid musicological foundation](https://www.harrisonmusic.com/), making it a good choice as the scope of my own work grows and deepens. It's also been a pleasure interacting with [its maintainer](https://github.com/no-chris/). The module is able to parse iReal Pro chord notation without issues, and its output is largely compatible with MusicXML's harmonic structure, which made it [relatively easy to adapt to my purposes](https://github.com/infojunkie/ireal-musicxml/blob/v1.0.1/src/musicxml.js#L824-L914), despite the complexity of the task at hand.

### Emulating the iReal Pro playback model

iReal Pro's information model pragmatically structures the musical information into "cells", with a fixed number of cells (16 of them) per row (which corresponds to a [single-staff system](https://en.wikipedia.org/wiki/Staff_(music))). As such, a cell does _not_ correspond to a single beat, because barlines can be positioned anywhere within the row. In addition, a chord's minimum duration is one beat. The algorithm used by iReal Pro to [determine the onset and duration of chords inside a measure is undocumented](https://www.irealb.com/forums/showthread.php?25161-Using-empty-cells-to-control-chord-duration), and I needed to perform many experiments with different time signatures to reach a [conversion algorithm that performs adequately](https://github.com/infojunkie/ireal-musicxml/blob/v1.0.1/src/musicxml.js#L712-L760) for the cases I have tested.

### Ensuring compatibility with other software

For the generated MusicXML to be practically useful, it needs to be compatible with other software that process MusicXML files. For the moment, I focus on ensuring compatibility with [MuseScore](https://musescore.org/), the excellent open source notation system, and with [OpenSheetMusicDisplay (OSMD)](https://opensheetmusicdisplay.github.io/), a well-maintained JavaScript module that renders MusicXML in Web documents (and that itself uses the equally impressive [VexFlow module](https://github.com/0xfe/vexflow) to perform the actual engraving).

MusicXML is a complex, ambitious and constantly evolving format that aims at capturing both music _notation_ and _playback_ information for a wide range of applications, of which leadsheets is but a single use-case. As a result, any system that supports MusicXML is bound to continuously expend effort into refining and maintaining its MusicXML processing routines. Throughout my work on the conversion module, I am interacting with the [MuseScore](https://musescore.org/en/node/313008) and [OSMD](https://github.com/opensheetmusicdisplay/opensheetmusicdisplay/issues/919) maintainers in order to iron out the details of how their systems process and interpret the format. I'm also participating in discussions with the [MusicXML designers and community](https://github.com/w3c/musicxml/issues/349), to help clarify and refine the specification of the format regarding my current area of focus. It is surely one of the thrills of working on open systems to be able to interact with so many motivated, smart and helpful groups of people.

## Next steps and the bigger vision

As my conversion module reaches an operational (but far from complete or robust) stage, I am ready to focus on the next step of my larger vision of an [open suite of Web-based tools that help musicians collaborate around sheet music](https://github.com/users/infojunkie/projects/2), which I prefer to keep vague at the moment, until the details crystallize organically. The next step will ensure that OSMD fully renders the generated MusicXML, in preparation for step 3 where a Web-based music player is added to the mix. A few years ago, I had created a [demo of this playback capability](https://ethereum.karimratib.me:8080/), and I intend to refine my earlier approach when the time comes.

This blog does not yet allow comments (mainly because I don't want to use a closed-content commenting service and I'd rather focus on the music tech), but if you are interested in this work, have something to contribute or to share, I'd love to hear from you! Feel free to [email me](mailto:karim.ratib@gmail.com) or [open issues on the relevant repo](https://github.com/infojunkie/ireal-musicxml/issues).

As always, happy coding! :saxophone:
