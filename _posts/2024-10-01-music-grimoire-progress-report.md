---
layout: post
title: "Music Grimoire: A progress report"
date: 2024-10-01
category: music
description: In this post, I present a summary of the music ecosystem I've been working on for the past 7 years.
image: /assets/music-workflow.png
---
About 7 years ago, I had a flash of insight: Music software is strongly biased towards Western mainstream music, and most tools are programmed with the "axioms" of this music as their foundation. Things like 12 notes per octave, tuned to intervals that are specific to the 12-TET tuning, with predefined scales and modes - these are hard-coded into the lowest layers of most music software and make it almost impossible to express musical ideas outisde this framework.

I [wrote a manifesto of sorts]({% post_url 2018-01-05-music-l10n %}) about it and naively set off to code my way out of this situation. I was driven by my own musical interests: Rediscovering and arranging songs from the popular Arabic repertoire into modern idioms. Although I achieved [a modest milestone towards that particular goal](https://musescore.com/user/55682/sets/2178286), it opened up a universe of questions and possibilities about how music is computed, notated, played back. I have not stopped learning and coding in this space since then.

Here is a snapshot of where I am in this journey, and where (I think) I am headed.

## An open source, standards-based, Unix-inspired, global-music ecosystem
At the core of my vision is an ecosystem of tools for publishing interactive musical ideas, ultimately delivered through the Web. The target audience includes music practitioners and institutions that are looking to publish interactive music material on the Web, like music teachers, university departments, cultural heritage institutions. Of course, Web-based music publishing already exists: It _is_ possible to [embed music scores via various platforms]({% post_url 2020-10-08-music-blogging %}). But these platforms are proprietary, commercial, unextensible, and Western-music-centric. To me, this feels short-sighted for something as important as music. I am aiming for something better.

To produce an open music publishing system for the Web, I need to build on open standards:
- [MusicXML](https://www.w3.org/2021/06/musicxml40/) is the W3C format for music sheet exchange - based on XML that I've come to appreciate for its maturity and incredible ecosystem of tools
- [Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) is the W3C API for producing audio within Web applications.
- [Web MIDI API](https://developer.mozilla.org/en-US/docs/Web/API/Web_MIDI_API) is the W3C API for integrating Web applications into the 40+ years old MIDI specification for digital music communication.
- [SMuFL](https://www.smufl.org/) is a Unicode extension to represent musical symbols, also part of the W3C Music Notation Community Group with maintains MusicXML.

By careful adherence to these standards, music applications can be built to transcend the limiting assumptions of Western mainstream practice. In some cases, [it is necessary to get involved in tweaking the standards](https://github.com/w3c/smufl/issues/44), and in many cases, [open source implementations of these standards are incomplete or incorrect and need fixing](https://github.com/musescore/MuseScore/pull/6693).

The general workflow I have in mind for music publishing involves the following steps:
- Express musical ideas into MusicXML (by explicit score writing or by generation from other sources)
- Convert MusicXML to MIDI for playback (with optional augmentation such as auto-generated accompaniments)
- Load MusicXML in a Web player for display using existing components such as [OSMD](https://opensheetmusicdisplay.org), [Verovio](https://verovio.org), etc.
- Play MIDI in the Web player via Web MIDI or Web Audio using existing components such as [Tone.js](https://tonejs.github.io/), [WebAudioFont](https://surikov.github.io/webaudiofont/), etc.

{% include image.html url="/assets/music-workflow.svg" width="100%" description="The general music workflow from score production to playback." %}

What follows is a quick overview of the tools that I am maintaining to support this workflow.

## Lead sheets to MusicXML
For pop/rock/jazz players, lead sheets are essential to convey the crux of a tune. To support the use case of playing lead sheets, I've created [`ireal-musicxml`, a library to convert iReal Pro lead sheets to MusicXML](https://github.com/infojunkie/ireal-musicxml). For example, this iReal Pro tune:

{% include image.html url="/assets/9.20-special-ireal.jpg" description="The original iReal Pro tune." %}

{% include image.html url="/assets/9.20-special-musescore.jpg" description="MuseScore's rendering of <code>ireal-musicxml</code>'s output." %}

## MusicXML to MIDI with accompaniment
To support conversion of MusicXML to MIDI, I've created [`musicxml-midi`, a library and API server](https://github.com/infojunkie/musicxml-midi) that supports the addition of auto-generated accompaniments via [another open source tool](https://www.mellowood.ca/mma/) that I've adopted and enhanced. Here's how the same tune above is played back with accompaniment:

{% include midi.html url="/assets/9.20-special.mid" %}

## Groove to MusicXML
This library also includes [`musicxml-grooves`, a tool to convert raw "grooves" (i.e. accompaniment patterns) into MusicXML sheets](https://github.com/infojunkie/musicxml-midi/blob/main/src/js/musicxml-grooves.js). This is how the following MIDI groove is interpreted by MuseScore and by `musicxml-grooves`:

{% include midi.html url="/assets/JazzBasieA.mid" %}

{% include image.html url="/assets/JazzBasieA-musescore.jpg" width="100%" description="The MIDI file as interpreted by MuseScore." %}

{% include image.html url="/assets/JazzBasieA.jpg" width="100%" description="The same pattern as interpreted by <code>musicxml-grooves</code> (without post-editing). This version is more readable than the above because the converter tries hard to quantize the notes to a grid that includes triplets." %}

## MusicXML to MuseScore
[MuseScore](https://musescore.org) is one of the few serious open source music writing software, but it suffers from incomplete MusicXML import/export. I've recently started work on [`musicxml-mscx`, a new library to perform more robust MusicXML conversion to and from the native MuseScore format](https://github.com/infojunkie/musicxml-mscx).

{% include image.html url="/assets/tutorial-apres-un-reve.finale.jpg" width="100%" description="The original score, converted to MusicXML by Finale." %}

{% include image.html url="/assets/tutorial-apres-un-reve.jpg" width="100%" description="<code>musicxml-mscx</code>'s output to MuseScore format. Note that MuseScore does not support cross-staff beams at the logical level." %}

{% include image.html url="/assets/tutorial-apres-un-reve.musescore.jpg" width="100%" description="MuseScore's own MusicXML importer. Can you spot the differences between the 3 displays?" %}

## Putting it all together: A Web-based audio player
Once the music assets are produced, they are ready to be loaded in a Web application. For this purpose, I've created [`musicxml-player`, a Web component that loads MusicXML and MIDI files](https://github.com/infojunkie/musicxml-player), in order to synchronize the audio playback with the animation of the music sheet. It's an ambitious component that packages several 3rd-party modules into a flexible foundation to build Web-based music applications. Here are 2 video captures from the demo app in the component's repo:

{% include video.html url="/assets/baiao.webm" description="A video capture of a looping rhythm." %}

{% include video.html url="/assets/salma-ya-salama.webm" description="A video capture of a score playback with auto-generated accompaniment." %}

## The challenges and rewards of this project
Writing this post, I realize I came a long way since that original manifesto in 2018... and that the road ahead is arbitrarily long. To remain motivated, I keep challenging myself to mini-projects that tickle my immediate fancy, and I do my best to fit them within the general framework of this ecosystem. I am constantly faced with new questions, from deeply philosophical ones to immediate programming problems:

- What are musical tunings, from a mathematical point of view? Why are the frequencies of the notes the way they are?
- What are the commonalities and differences between Western scales, Arabic maqams, Indian ragas, and musical modes from other world cultures?
- How to represent the musics of different cultures in a single programming system, without completely diluting the former and keeping the latter manageable?
- How to extract from MIDI events a sequence of notes that is understandable and playable by humans?
- How to reliably schedule notes from a MIDI file to be played in real-time on a Web page?
- How to link the information in a MusicXML score to the audio events in a MIDI file?
- What the heck is XSL and how can I write data transformations with it??

Answering these questions is the reason why I am still motivated to go on! Over the course of the years, I've encountered some truly inspiring projects that have expanded my musicological mind. Here are a few:

- Gareth Loy's ["Musimathics: A Guided Tour of the Mathematics of Music"](http://www.musimathics.com/)

{% include image.html description="Musimathics blows my mind every time I pick it up 🤯" width="100%" url="/assets/musimathics.jpg" %}

- Manuel Op de Coul's [Scala](https://www.huygens-fokker.org/scala/), a mind-bogglingly comprehensive tool for exploring musical tunings.

{% include image.html url="/assets/scala-keyboard.png" width="100%" description="One of countless feature-rich functions of Scala." %}

- Chris Wilson's [A tale of two clocks](https://web.dev/articles/audio-scheduling), the seminal article about robust Web audio sequencing.

{% include image.html description="A wonderfully explanatory diagram that captures the essence of the technique." width="100%" url="/assets/a-tale-of-two-clocks.png" %}

I've been fortunate to work with others who are interested in this domain: A year ago, I was sponsored to add a "horizontal scrolling" mode to the player, as well as a method to synchronize the playback with a YouTube video (hint: it uses the [Timing Object W3C draft specification](https://webtiming.github.io/timingobject/)) - both of which went back into `musicxml-player`. Today, I am exploring adding multiplayer capability to the player, also using Web standards. I'm also fortunate to interact with like-minded developers, like [Christoph Guttandin](https://media-codings.com/) who maintains a dizzying array of well-crafted audio modules - we collaborate on his excellent [`midi-player` component](https://github.com/chrisguttandin/midi-player) which is a cornerstone of `musicxml-player`. Since the early days, I've been in touch with [Bob van del Poel](https://www.mellowood.ca), a fellow British Columbian who wrote the ridiculously great [Musical MIDI Accompaniment (MMA)](https://www.mellowood.ca/mma/) system which is a cornerstone of `musicxml-midi`.

## Looking ahead one year
Here's what I hope to work on within the next year:

- Embed playable music sheets into actual CMS systems, starting with my own [Arabic Real Book sheets](https://musescore.com/user/55682/sets/2178286) - [GitHub issue here](https://github.com/infojunkie/musicxml-player/issues/41).

- Reach a milestone with `musicxml-mscx` to convert full music scores from MusicXML to MuseScore format - focusing on correctly handling the bugs in MuseScore's own MusicXML import.

- Explore the feasibility of using pre-rendered scores in `musicxml-player` to replace resource-intensive JavaScript notation engines - [GitHub issue here](https://github.com/infojunkie/musicxml-player/issues/38).

- Replace my simplistic MIDI soft-synth in `musicxml-player` with a more complete one such as SpessaSynth - [GitHub issue here](https://github.com/infojunkie/musicxml-player/issues/39).

- Explore multiplayer playback in `musicxml-player` - [GitHub issue here](https://github.com/infojunkie/musicxml-player/issues/40).

- Support microtonality in MusicXML to MIDI conversion - [GitHub issue here](https://github.com/infojunkie/musicxml-midi/issues/45).

- Expand the groove conversion algorithm in `musicxml-grooves` to handle full MIDI files - [GitHub issue here](https://github.com/infojunkie/musicxml-midi/issues/53).

I hope to continue working on this project for a long time to come, and I welcome any and all contributions! :handshake:
