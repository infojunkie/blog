---
layout: post
title: "Music Grimoire / music-i18n: 2025 progress report"
date: 2025-10-07
category: music
description: In this post, I present a summary of the work done last year on my music project. The focus has been on realizing the vision of <code>music-i18n</code> by creating a full microtonal pipeline from MusicXML to MIDI and Web playback.
image: assets/musicxml-player-static.jpg
---
In 2025, I had entirely too much fun working on the Music Grimoire / `music-i18n` project. After a few years of slow progress, my productivity shot through the roof this year! No doubt motivated by the interest that other members of the music coding community showed in the work, and the fruitful cooperations that ensued.

## Contents
* [A review of last year's goals](#a-review-of-last-years-goals)
* [A concrete project to focus the attention](#a-concrete-project-to-focus-the-attention)
* [A generic pipeline for microtonal music](#a-generic-pipeline-for-microtonal-music)
* [What is a musical tuning?](#what-is-a-musical-tuning)
* [Adding microtonal support to Verovio](#adding-microtonal-support-to-verovio)
* [The multiple accidentals controversy](#the-multiple-accidentals-controversy)
* [More tuning toys](#more-tuning-toys)
* [What is `music-i18n`, really?](#what-is-music-i18n-really)
* [Goals for the coming year](#goals-for-the-coming-year)

## A review of last year's goals
Around the same time last year, I presented a [progress report of where I was with my music work]({% link _posts/2024-10-01-music-grimoire-progress-report.md %}). It ended with the following goals for this year:

- _Embed playable music sheets into actual CMS systems, starting with my own Arabic Real Book sheets._ I did not work on this goal at all :cry: BUT! I did get involved in an exciting music publishing project that I will share below.

- _Reach a milestone with `musicxml-mscx` to convert full music scores from MusicXML to MuseScore format._ I did reach a good milestone with this work. I focused on rendering style beyond what MusicXML affords, by accepting user-defined MuseScore stylesheets (`.mss`, which can be created from within MuseScore's style settings) in the conversion process. For example, this module can now produce stylized MuseScore lead sheets like the following:

{% include image.html url="/assets/9-20-special-mscx.jpg" width="100%" description="A stylized MuseScore lead sheet produced by musicxml-mscx with a user-defined .mss stylesheet." %}

- _Explore the feasibility of using pre-rendered scores in `musicxml-player` to replace resource-intensive JavaScript notation engines._ I dug deep to understand the various assets produced by MuseScore and Verovio cli tools. The outcome of this work was to create new `musicxml-player` classes `MuseScoreConverter`, `MuseScoreRenderer`, `VerovioStaticConverter`, `VerovioStaticRenderer` which accept asset files from these respective engravers, and require no additional JavaScript modules to render and interact with the scores. In brief, those engravers produce the following assets: SVG files for the rendered score, MIDI files for playback, and JSON metadata that describe how the various music objects (notes, measures, etc.) are laid out in time and space. The converter and renderer classes parse those various files to integrate them into the main player. Here's an example of a simple score rendered to SVG / MIDI by Verovio and displayed by the [MusicXML Player demo](https://blog.karimratib.me/demos/musicxml/?sheet=data/blackwood-ex-29.musicxml):

{% include image.html url="/assets/musicxml-player-static.jpg" width="100%" description="The MusicXML Player can render static assets produced by various engravers." %}

- _Replace my simplistic MIDI soft-synth in `musicxml-player` with a more complete one such as SpessaSynth._ I spent a few weeks integrating the awesome [SpessaSynth](https://spessasus.github.io/SpessaSynth/), and participating with its author to test their brand-new TypeScript version. This browser-based MIDI synth has an impressive list of features, and for me the deciding factor to adopt it was its support for [MIDI Tuning Standard (MTS)](https://en.wikipedia.org/wiki/MIDI_tuning_standard), which is an indispensable component of `music-i18n` (more on this below). Other than the synthesizer, SpessaSynth also features a mature sequencer that allowed me to significantly simplify my code and simultaneously gain exciting new features. The above screenshot of the latest version of the MusicXML Player shows how SpessaSynth is being used: As a local synth, as a sequencer, and as an external synth exposing a Web MIDI port. A major win on many fronts! :tada:

- _Explore multiplayer playback in `musicxml-player`._ Honestly, I don't know what got into me to mention this as a goal :roll_eyes: :shrug: I didn't spend a single cycle thinking about this. Next!

- _Support microtonality in MusicXML to MIDI conversion._ This goal, on the other hand, is where I spent the great majority of the year. It was all triggered by a fellow coder reaching out for my help with their [Arabic sheet music website Maqamatna](https://www.maqamatna.com/), to enhance the sheet page with an online music player (exactly like `musicxml-player` that I've been working on!) The big issue with Arabic music is that it includes notes (pitches) that are tuned differently than Western music, sort of like blues bends that are stuck halfway between a fret and the next on the guitar. This necessitates a rethink of the full music production pipeline, from music engraving to MIDI file production to online playback. Since this is the central use-case for my `music-i18n` vision, I gladly accepted this opportunity to jump into a concrete project that would challenge and solidify my vision. And how challenged I was! I will spend the rest of this post describing the details of the work that ensued.

- _Expand the groove conversion algorithm in `musicxml-grooves` to handle full MIDI files._ Given the above, I could not devote much attention to this fascinating problem. My research led me to some very interesting academic experiments such as [qparselib](https://hal.science/hal-05230366v1) (which has unfortunately gone closed-source recently). I hope to return to this problem in the future.

## A concrete project to focus the attention
There's nothing like a concrete project to crystallize a vision and challenge one's fanciful assumptions against the cold, hard reality. When the Maqamatna author contacted me to apply my (claimed) expertise to their website, I knew I had found this opportunity and this challenge. I was a little nervous, because up to this point many details of my `music-i18n` vision had been left as exercises to the proverbial reader. Now, I needed to deliver on my claims. After a few sessions of elicitation and brainstorming, we put together a plan of action. In order to enhance the song page with playback, both the backend and the frontend need modifications:

{% include image.html url="/assets/maqamatna.jpg" width="100%" description="The tasteful design of Maqamatna song page needs to be augmented with a sheet music player." %}

We quickly agreed that the pipeline I had been working on applies well for this use-case:

{% include image.html url="/assets/maqamatna-workflow-dark.svg" link="/assets/maqamatna-workflow.svg" width="100%" description="The general music workflow from score production to playback, including the selected technologies and formats." %}

This high-level plan had many, many details to fill in. Most importantly, we had to select the technologies to generate the static assets on the backend and to render them visually and aurally on the frontend. The requirements are:

- Generator can be invoked as a headless console tool
- Generator and renderer support Arabic music, including text, accidentals, tunings
- Renderer can play back the music with custom tunings - solved by integrating SpessaSynth as discussed earlier

Out of the box, both MuseScore and Verovio support the first requirement, but not the second. In fact, microtonal / xenharmonic / world music support is severely lacking in most music software, especially in the open source domain. Even MusicXML, the W3C standard for music notation, does not address the question of microtonal music except in the most simplistic way of [specifying the pitch alteration for each note separately](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/). It has no concept of a "tuning": How each degree in a scale is tuned, how it is represented in musical notation and how it maps to a MIDI key.

This was the main puzzle that I spent the following several months solving.

## A generic pipeline for microtonal music
I wanted to design a pipeline for microtonal music that would require the least modifications to existing softwares, and preferably none to existing standards. For each step in the pipeline above, we need to ensure that the important music features for this project are correctly preserved:

The pipeline starts with a MuseScore score that includes non-standard accidentals and possibly non-standard key signatures. MuseScore exports MusicXML files which are reasonably faithful to the original, including the correct accidentals and key signatures. In terms of accidentals, MusicXML supports [SMuFL symbols, which is another W3C standard that functions as an add-on to Unicode specialized in music symbols](https://www.smufl.org/). Although MuseScore also supports SMuFL accidentals, it exports them to MusicXML incorrectly and thus needs to be corrected (either by patching or by post-processing the output MusicXML document).

The next step is to convert the MusicXML to visual and audio assets that are passed to the frontend. I selected the excellent engraver [Verovio](https://www.verovio.org) as the main conversion engine, instead of either MuseScore or my own `musicxml-midi` module. Verovio is attractive because it is a C++ console tool that specializes in converting scores to such assets, as opposed to MuseScore which is weighed down by a full GUI application. Verovio's full functionality is also [cross-compiled to WASM](https://www.npmjs.com/package/verovio), making it doubly-attractive because any fixes to the backend would automatically reflect on the frontend. After evaluating Verovio's almost-comprehensive MIDI output, I came to the conclusion that spending the effort understanding its codebase and patching it to fill the gaps would be much more efficient that recreating a full-featured and robust MIDI converter in my own `musicxml-midi` module. I decided to [rethink the conversion pipeline of `musicxml-midi`](https://github.com/infojunkie/musicxml-midi/issues/54) to delegate the MIDI conversion to Verovio, and focus instead on generating automatic accompaniment using MMA in this module. Since accompaniment generation is not a feature of the Maqamatna project, I left this part for later and kept going.

Now Verovio comes with its own set of challenges and idiosyncrasies. For one, its internal document representation is not based on MusicXML, but on [MEI (Music Encoding Initiative)](https://music-encoding.org/), another widely used music notation format. This means that whatever work I do in Verovio will also have to be compatible with MEI :sob: In my calculations, this was an unavoidable cost I would have to absorb. Fortunately, MEI is a mature format that is largely compatible with MusicXML so I was reasonably confident that the balance still tilted in the positive.

What is missing from Verovio to implement the microtonal features needed by Maqamatna?
- Specifying a tuning that Verovio should apply to the MIDI export
- Converting that tuning to MTS (MIDI Tuning Standard) during MIDI export
- Carrying over non-standard accidentals in the score from one note to the next, including non-standard accidentals in the key signature
- Mapping notes/accidentals to their expected entries in the tuning, and thus exporting them correctly to MIDI

## What is a musical tuning?
Whenever questions of musical tunings arise, the first place to check is the [incredible Scala application](https://www.huygens-fokker.org/scala/index.html), which is considered to be the reference implementation for all things microtonal. Scala [has defined the de-facto standard to describe tunings](https://www.huygens-fokker.org/scala/scl_format.html).

A tuning defines how each note should be tuned (i.e. its pitch) relative to some base note. Because the tuning is relative, we're not using actual frequencies in Hertz but rather frequency ratios (for example, the octave ratio is 2/1 of the base note), or a logarithmic scale in units called "cents" where 1200 cents correspond to one octave, and 1200/12 = 100 cents correspond to one semitone. Here's a Scala SCL file for the most common Arabic tuning, which in addition to the common 12 Western musical tones, includes 12 other tones tuned halfway between pairs of semitones (called quarter-tones):

```
! 24-edo.scl
!
! This is a comment.
!
! Tuning description:
24 equal divisions of an octave. 24 proportionally equal and equal sounding semitone intervals per octave.
!
! Count of tones:
24
!
! List of tones:
50.0
100.0
150.0
200.0
250.0
300.0
350.0
400.0
450.0
500.0
550.0
600.0
650.0
700.0
750.0
800.0
850.0
900.0
950.0
1000.0
1050.0
1100.0
1150.0
2/1
```

This information alone is not enough to produce a MIDI file from a musical score. There are questions left unanswered:
- What is the actual frequency of each tone in the different octaves?
- How will notes in the score map to the tones above?
- How will the tones map to MIDI notes in the output MIDI file?

To answer these questions, we need to supply more information. After some research, I found that Ableton, the makers of the famous [Live DAW (Digital Audio Workstation)](https://www.ableton.com/en/live/), have created an [extension to the Scala SCL format](https://help.ableton.com/hc/en-us/articles/10998372840220-ASCL-Specification) that answers these very questions:

```
! 24-edo.ascl
!
! This is a comment.
!
! Tuning description:
24 equal divisions of an octave. 24 proportionally equal and equal sounding semitone intervals per octave.
!
! Count of tones:
24
!
! List of tones:
50.0
100.0
150.0
200.0
250.0
300.0
350.0
400.0
450.0
500.0
550.0
600.0
650.0
700.0
750.0
800.0
850.0
900.0
950.0
1000.0
1050.0
1100.0
1150.0
2/1
!
!!! ASCL EXTENSIONS START HERE !!!
!
! @ABL NOTE_NAMES "Bs/C" "C1qs" "Cs/Df" "Dbf" "D" "D1qs" "Ds/Ef" "Ebf" "E/Ff" "E1qs/Fbf" "Es/F"  ↩
"F1qs" "Fs/Gf" "Gbf" "G" "G1qs" "Gs/Af" "Abf" "A" "A1qs" "As/Bf" "Bbf" "B/Cf" "B1qs/Cbf"
! @ABL REFERENCE_PITCH 4 0 261.6256
```

Here, the ASCL file augments the SCL file with `@ABL` entries that specify the note names as they are expected to be found in the score, and a reference tone from which all other tones can be computed and which maps to the MIDI key 60 (midpoint-ish between 0-127). I gladly adopted the Ableton ASCL format to supply tuning information to Verovio, instead of inventing yet another format that would pollute the collective cognitive field :exploding_head:

## Adding microtonal support to Verovio
Now I needed some C++ code to integrate ASCL parsing and processing inside Verovio. As I am loath to create unnecessary new code, I found a [header-only C++ library that parses Scala SCL files](https://github.com/surge-synthesizer/tuning-library), maintained by the same team that maintains the excellent [open-source synth Surge XT](https://surge-synthesizer.github.io/). Since ASCL provides relatively few extensions to SCL, I decided to take a chance and attempt a PR to add ASCL support to this library. In about a month, and thanks to the willingness and help of the library maintainers, I was able to [get my changes integrated into `tuning-library`](https://github.com/surge-synthesizer/tuning-library/pull/77) :tada:

With this PR done, I dove into the Verovio codebase. I've been working on [a fork of the repo](https://github.com/infojunkie/verovio) for 3 months now, and I've reached a point where microtonal support is fully functional in both the console tool and the WASM module. The "theory of operation" of microtonal support goes as follows:

First, Verovio needs to accept Ableton ASCL tunings, whether in MusicXML files via the existing element [`play/other-play[@type='tuning-ableton']`](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/other-play/), or passed to the console tool via an option `verovio --tuning /path/to/tuning-file.ascl`, or in the JavaScript bindings via a new attribute `VerovioOptions.tuning` which takes an ASCL definition.

Here's how the tuning looks when it's embedded in a MusicXML file:

```xml
  [..]
  <part id="P1">
    <measure number="1" width="224.66">
      <sound>
        <play>
          <other-play type="tuning-ableton">
            <![CDATA[
! blackwood_15.ascl
!
15-EDO with Easley Blackwood's Ups and Downs Notation adapted for MusicXML / MEI.
!
15
!
80.
160.
240.
320.
400.
480.
560.
640.
720.
800.
880.
960.
1040.
1120.
1200.
!
! Note names are formatted per MusicXML accidentals.
!
! @ABL NOTE_NAMES B/C Cnatural-up/Dflat-up Csharp-down/Dnatural-down D/Eflat Dnatural-up/Eflat-up  ↩
Dsharp-down/Enatural-down E/F Fnatural-up/Gflat-up Fsharp-down/Gnatural-down G/Aflat Gnatural-up/Aflat-up  ↩
Gsharp-down/Anatural-down A/Bflat Anatural-up/Bflat-up Asharp-down/Bnatural-down
! @ABL REFERENCE_PITCH 4 0 261.6256
! @ABL SOURCE 15 equal temperament, Wikipedia.
! @ABL LINK https://en.wikipedia.org/wiki/15_equal_temperament
            ]]>
            </other-play>
          </play>
        </sound>
      <attributes>
  [..]
```
and in JavaScript:

```js
import createVerovioModule from 'verovio/wasm';
import { VerovioToolkit } from 'verovio/esm';

createVerovioModule().then(async VerovioModule => {
  const verovioToolkit = new VerovioToolkit(VerovioModule);
  const score = await (await fetch('/path/to/score.musicxml')).text();
  verovioToolkit.loadData(score);
  verovioToolkit.setOptions({
    font: 'Bravura',
    tuning: `
! 24-edo.ascl
!
24 equal divisions of an octave. 24 proportionally equal and equal sounding semitone intervals per octave.
!
! default tuning: degree 18 (900.0 cents) 440 Hz, or degree 0 = 261.625565 Hz
!
24
!
50.
100.
150.
200.
250.
300.
350.
400.
450.
500.
550.
600.
650.
700.
750.
800.
850.
900.
950.
1000.
1050.
1100.
1150.
2/1
!
! Note names are formatted per MEI accidentals.
!
! @ABL NOTE_NAMES Bs/C C1qs Cs/Df Dbf D D1qs Ds/Ef Ebf E/Ff E1qs/Fbf Es/F F1qs Fs/Gf Gbf G G1qs Gs/Af  ↩
Abf A A1qs As/Bf Bbf B/Cf B1qs/Cbf
! @ABL REFERENCE_PITCH 4 0 261.6256
! @ABL NOTE_RANGE_BY_INDEX 0 21 6 4
! @ABL LINK https://www.ableton.com/learn-more/tuning-systems/24-edo
    `.trim()
  })
});
```

The proverbial astute reader will have noticed that the `@ABL NOTE_NAMES` differ in the MusicXML case from the Verovio case. In the former, the accidentals are formulated as [MusicXML accidentals](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/accidental-value/), whereas in the latter, they are formulated as [MEI accidentals](https://music-encoding.org/guidelines/v5/data-types/data.ACCIDENTAL.WRITTEN.html). It's worth mentioning that neither MusicXML nor MEI encompass the full set of [SMuFL accidentals](https://danielku15.github.io/smufl-viewer/?search=accidental) (488 at the latest count), so in both cases SMuFL accidentals are also recognized as valid names.

Once stored in Verovio's internal data store, the tuning is ready to be used during MIDI export. This happens in two steps:

1. Export an MTS (MIDI Tuning Standard) message based on the tuning information above. This is a [MIDI SysEx message](https://midi.org/midi-tuning-updated-specification) to which we pass the retuned frequencies of all 128 MIDI keys. The new frequencies are computed by `tuning-library`.

2. With the MIDI tuning now in place, we need to find the MIDI key that corresponds to each note in the score. For this, we maintain a map between the incoming `@ABL NOTE_NAMES` and the tuning entries. Again, `tuning-library` knows how to map tuning entries to MIDI keys, so we output this result to the MIDI file, instead of the default MIDI key that would have been sent in the absence of a tuning.

To clarify what this means, let's look at the `24-edo.ascl` tuning file just above in the context of an actual score. For lovers of Arabic music, you can follow [Sami Abu Shumays' excellent maqam tutorials](https://www.youtube.com/watch?v=xN7E1pc8Y2Y&list=PLcfDkfaWrWRTX-UreYE-cY5rq9jkstHL3), of which this is an excerpt:

{% include image.html url="/assets/shumays.png" width="100%" description="A transcription of the intro to Sami Abu Shumays' first maqam lesson." %}

Examining this score, we find two half-flat notes: **B½♭** and **E½♭**, notated in their [typical Arabic / Turkish notation](https://danielku15.github.io/smufl-viewer/?search=accidentalQuarterToneFlatArabic). Expressed in [MEI syntax](https://music-encoding.org/guidelines/v5/data-types/data.ACCIDENTAL.aeu.html), this gives us **Bbf** and **Ebf**, which we can find in the `@ABL NOTE_NAMES` above, corresponding to 350¢ and 1050¢ respectively.

We now map the 24 tuning tones (per octave) to MIDI, starting at the `@ABL REFERENCE_PITCH` (C4) which we map to MIDI key 60. Here's the output of `tuning-library`'s utility `showmapping` with the tuning above, spanning all 128 MIDI keys:

```
$ showmapping 24-edo.ascl
Note,        Freq (Hz),        ScaledFrq,        logScaled,  Pos, Name
   0,    46.2493028390,     5.6568542495,     2.5000000000,   12, Fs/Gf
   1,    47.6045108553,     5.8226127314,     2.5416666667,   13, Gbf
[..]
  50,   195.9977179909,    23.9729132300,     4.5833333333,   14, G
  51,   201.7408895050,    24.6753732065,     4.6250000000,   15, G1qs
  52,   207.6523487900,    25.3984168315,     4.6666666667,   16, Gs/Af
  53,   213.7370270538,    26.1426472519,     4.7083333333,   17, Abf
  54,   220.0000000000,    26.9086852881,     4.7500000000,   18, A
  55,   226.4464920616,    27.6971699522,     4.7916666667,   19, A1qs
  56,   233.0818807590,    28.5087589805,     4.8333333333,   20, As/Bf
  57,   239.9117011864,    29.3441293825,     4.8750000000,   21, Bbf
  58,   246.9416506281,    30.2039780058,     4.9166666667,   22, B/Cf
  59,   254.1775933119,    31.0890221169,     4.9583333333,   23, B1qs/Cbf
  60,   261.6255653006,    32.0000000000,     5.0000000000,    0, Bs/C
  61,   269.2917795270,    32.9376715726,     5.0416666667,    1, C1qs
  62,   277.1826309769,    33.9028190195,     5.0833333333,    2, Cs/Df
  63,   285.3047020232,    34.8962474453,     5.1250000000,    3, Dbf
  64,   293.6647679174,    35.9187855459,     5.1666666667,    4, D
  65,   302.2698024408,    36.9712862999,     5.2083333333,    5, D1qs
  66,   311.1269837221,    38.0546276801,     5.2500000000,    6, Ds/Ef
  67,   320.2437002253,    39.1697133857,     5.2916666667,    7, Ebf
  68,   329.6275569129,    40.3174735966,     5.3333333333,    8, E/Ff
  69,   339.2863815897,    41.4988657488,     5.3750000000,    9, E1qs/Fbf
  70,   349.2282314330,    42.7148753334,     5.4166666667,   10, Es/F
  71,   359.4613997130,    43.9665167187,     5.4583333333,   11, F1qs
  72,   369.9944227116,    45.2548339959,     5.5000000000,   12, Fs/Gf
  73,   380.8360868427,    46.5809018509,     5.5416666667,   13, Gbf
  74,   391.9954359817,    47.9458264601,     5.5833333333,   14, G
  75,   403.4817790101,    49.3507464131,     5.6250000000,   15, G1qs
  76,   415.3046975799,    50.7968336630,     5.6666666667,   16, Gs/Af
  77,   427.4740541076,    52.2852945037,     5.7083333333,   17, Abf
  78,   440.0000000000,    53.8173705762,     5.7500000000,   18, A
  79,   452.8929841231,    55.3943399044,     5.7916666667,   19, A1qs
  80,   466.1637615181,    57.0175179610,     5.8333333333,   20, As/Bf
  81,   479.8234023727,    58.6882587651,     5.8750000000,   21, Bbf
  82,   493.8833012561,    60.4079560116,     5.9166666667,   22, B/Cf
  83,   508.3551866238,    62.1780442338,     5.9583333333,   23, B1qs/Cbf
  84,   523.2511306012,    64.0000000000,     6.0000000000,    0, Bs/C
  85,   538.5835590540,    65.8753431452,     6.0416666667,    1, C1qs
  86,   554.3652619537,    67.8056380390,     6.0833333333,    2, Cs/Df
  87,   570.6094040464,    69.7924948906,     6.1250000000,    3, Dbf
  88,   587.3295358348,    71.8375710918,     6.1666666667,    4, D
  89,   604.5396048816,    73.9425725998,     6.2083333333,    5, D1qs
  90,   622.2539674442,    76.1092553602,     6.2500000000,    6, Ds/Ef
  91,   640.4874004506,    78.3394267715,     6.2916666667,    7, Ebf
  92,   659.2551138257,    80.6349471933,     6.3333333333,    8, E/Ff
  93,   678.5727631795,    82.9977314977,     6.3750000000,    9, E1qs/Fbf
  94,   698.4564628660,    85.4297506669,     6.4166666667,   10, Es/F
  95,   718.9227994261,    87.9330334373,     6.4583333333,   11, F1qs
  96,   739.9888454233,    90.5096679919,     6.5000000000,   12, Fs/Gf
  97,   761.6721736854,    93.1618037019,     6.5416666667,   13, Gbf
  98,   783.9908719635,    95.8916529201,     6.5833333333,   14, G
  99,   806.9635580201,    98.7014928261,     6.6250000000,   15, G1qs
[..]
 127,  1811.5719364925,   221.5773596176,     7.7916666667,   19, A1qs
```

From this table, Verovio is now able to output the correct notes to the MIDI file! [Here's what this particular transcription sounds like](https://blog.karimratib.me/demos/musicxml/?sheet=data/shumays.musicxml).

## The multiple accidentals controversy
Are multiple accidentals per note accepted in music theory?

The answer seems to vary depending on who you ask. But for `music-i18n`, the answer is a resounding YES! Witness this excerpt from the Extended Helmholtz-Ellis JI Pitch Notation booklet:

{% include image.html url="/assets/notation-heji.png" width="100%" description="The Extended Helmholtz-Ellis JI Pitch Notation supports multiple accidentals that fine-tune the pitch of playable notes." %}

Or this microtonal tune written in the encyclopedic Sagittal Notation:

{% include image.html url="/assets/notation-sagittal.png" width="100%" description="Sagittal Notation includes two modes of expressing accidentals: Mixed (top) and pure (bottom). Mixed notation combines new symbols with traditional sharps and flats." %}

Software support for multiple accidentals is also uneven:

- MusicXML flatly does not support multiple accidentals per note, because [the `note/accidental` element is only accepted once](https://github.com/w3c/musicxml/blob/gh-pages/schema/musicxml.xsd#L5226). I sadly resolved to [fork and patch the MusicXML schema to support multiple accidentals](https://github.com/infojunkie/musicxml/commit/eb9648564a729b1acdc3e91daeecc09ce72e8d89), until I prepare a good case to support this feature in the official version :sweat_smile:

- Whereas [MEI does technically support the notion of multiple accidentals per note, it seems the Verovio maintainers are unsure about it](https://github.com/rism-digital/verovio/issues/4185). Which means it's up to me to ensure this support fully works for MusicXML import, MIDI export and even regular visual engraving :sweat_smile: :sweat_smile:

## More tuning toys
In order to test the patched Verovio, I created some utilities to create tuning files. In the Unix spirit, those are small separate tools that are combined to build up the final result. It's best to be familiar with the Linux environment to run these comfortably:

- A [Python script](https://github.com/infojunkie/scalextric/blob/main/src/build/accidentals/sagittals.py) to convert the [Sagittal reference spreadsheet](https://sagittal.org/Sagittal-SMuFL-Map.ods) to JSON:

```json
{
    "accidentalNatural": {
        "range": "Conventional Sagittal-compatible accidentals",
        "unicode": {
            "character": "",
            "code_point": "U+E261"
        },
        "sagitype": {
            "long": {
                "revo_pure": "|//|",
                "evo_mixed": {
                    "comma": null,
                    "sharp_flat": "h or |//|"
                }
            },
            "short": {
                "evo_mixed": {
                    "comma": null,
                    "sharp_flat": "h"
                }
            }
        },
        "pitch": {
            "description": {
                "sharp_flat": "natural",
                "commatic_alteration": null,
                "direction": null
            },
            "cents": 0.0,
            "ratio": {
                "numerator": 1,
                "denominator": 1
            },
            "prime_count_vector": {
                "2": null,
                "3": null,
                "5": null,
                "7": null,
                "11": null,
                "13": null,
                "17": null,
                "19": null,
                "23": null,
                "29": null,
                "31": null,
                "37": null
            }
        },
        "ji_pitches": {
            "3^-2": null,
            "3^-1": null,
            "3^0": null,
            "3^1": null,
            "3^2": null
        },
        "notation_membership": {
            "prime_factor": null,
            "12_relative_fractions": "natural",
            "12_relative_cents": 0.0,
            "edo_degrees": {
                "17": 0,
                "19": 0,
                "22": 0,
                "27": 0,
                "29": 0,
                "31": 0,
                "34": 0,
                "39": 0,
                "41": 0,
                "43": 0,
                "46": 0,
                "50": 0,
                "53": 0,
                "60": 0,
                "72": 0,
                "96": 0
            }
        },
        "sagispeak": {
            "simple": {
                "spelling": null,
                "ipa_1": null,
                "ipa_2": null,
                "ipa_3": null,
                "ipa_4": null
            },
            "alternative": {
                "spelling": null,
                "ipa_1": null,
                "ipa_2": null,
                "ipa_3": null,
                "ipa_4": null
            },
            "sharp_flat": "natural"
        },
        "symbol": {
            "symbol_or_accent": "symbol",
            "shaft_count": null
        },
        "smufl": {
            "glyph_name": "accidentalNatural",
            "description": "Natural"
        },
        "glyph_description": {
            "graphical": "natural",
            "heraldic": "Hera's throne"
        }
    },
[..]
    "accSagittal11LargeDiesisUp": {
        "range": "Spartan Sagittal single-shaft accidentals (U+E300–U+E30F)",
        "unicode": {
            "character": "",
            "code_point": "U+E30C"
        },
        "sagitype": {
            "long": {
                "revo_pure": "(|)",
                "evo_mixed": {
                    "comma": "(|)",
                    "sharp_flat": null
                }
            },
            "short": {
                "evo_mixed": {
                    "comma": "m",
                    "sharp_flat": null
                }
            }
        },
        "pitch": {
            "description": {
                "sharp_flat": null,
                "commatic_alteration": "11-L-diesis",
                "direction": "up"
            },
            "cents": 60.412,
            "ratio": {
                "numerator": 729,
                "denominator": 704
            },
            "prime_count_vector": {
                "2": -6,
                "3": 6,
                "5": 0,
                "7": 0,
                "11": -1,
                "13": null,
                "17": null,
                "19": null,
                "23": null,
                "29": null,
                "31": null,
                "37": null
            }
        },
        "ji_pitches": {
            "3^-2": "128/99",
            "3^-1": "64/33",
            "3^0": "16/11",
            "3^1": "12/11",
            "3^2": "18/11"
        },
        "notation_membership": {
            "prime_factor": null,
            "12_relative_fractions": null,
            "12_relative_cents": null,
            "edo_degrees": {
                "17": null,
                "19": null,
                "22": null,
                "27": null,
                "29": null,
                "31": null,
                "34": null,
                "39": 3,
                "41": null,
                "43": null,
                "46": 3,
                "50": null,
                "53": null,
                "60": null,
                "72": null,
                "96": null
            }
        },
        "sagispeak": {
            "simple": {
                "spelling": "jatai",
                "ipa_1": "/dʒɐ ˈtaɪ/",
                "ipa_2": "/ʒɐ ˈtaɪ/",
                "ipa_3": "/jɐ ˈtaɪ/",
                "ipa_4": "/hɐ ˈtaɪ/"
            },
            "alternative": {
                "spelling": "wai",
                "ipa_1": "/waɪ/",
                "ipa_2": null,
                "ipa_3": null,
                "ipa_4": null
            },
            "sharp_flat": null
        },
        "symbol": {
            "symbol_or_accent": "symbol",
            "shaft_count": 1
        },
        "smufl": {
            "glyph_name": "accSagittal11LargeDiesisUp",
            "description": "11 large diesis up, (11L), (sharp less 11M), 3° up [46-EDO]"
        },
        "glyph_description": {
            "graphical": "double arc up",
            "heraldic": "Dionysus' wine cup"
        }
    },
[..]
}
```

- A [jq script](https://github.com/infojunkie/scalextric/blob/main/src/build/accidentals/merge_smufl_sagittals.jq) to convert the Sagittal JSON above + [SMuFL accidentals](https://github.com/w3c/smufl/blob/gh-pages/metadata/ranges.json) into a JSON map of accidental => pitch alteration. The resulting file needs to be edited manually for the missing accidentals - [see my current version](https://github.com/infojunkie/musicxml-midi/blob/main/src/smufl.json). This script was mostly vibe-coded and it took multiple iterations before :robot: got it right!!

```json
{
  "accidentalDoubleFlatArabic": -200,
  "accidentalThreeQuarterTonesFlatArabic": -150,
  "accidentalFlatArabic": -100,
  "accidentalQuarterToneFlatArabic": -50,
  "accidentalNaturalArabic": 0,
  "accidentalQuarterToneSharpArabic": 50,
  "accidentalSharpArabic": 100,
  "accidentalThreeQuarterTonesSharpArabic": 150,
  "accidentalDoubleSharpArabic": 200,
  "accidentalBuyukMucennebFlat": -181.1,
  "accidentalKucukMucennebFlat": -113.2,
  "accidentalBakiyeFlat": -90.6,
  "accidentalKomaFlat": -22.6,
  "accidentalKomaSharp": 22.6,
  "accidentalBakiyeSharp": 90.6,
  "accidentalKucukMucennebSharp": 113.2,
  "accidentalBuyukMucennebSharp": 181.1,
  "accSagittal7v11KleismaUp": 9.688,
  "accSagittal7v11KleismaDown": -9.688,
  "accSagittal17CommaUp": 14.73,
  "accSagittal17CommaDown": -14.73,
  "accSagittal55CommaUp": 31.767,
  "accSagittal55CommaDown": -31.767,
  "accSagittal7v11CommaUp": 33.148,
  "accSagittal7v11CommaDown": -33.148,
  "accSagittal5v11SmallDiesisUp": 38.906,
  "accSagittal5v11SmallDiesisDown": -38.906,
  "accSagittalSharp5v11SDown": 74.779,
  "accSagittalFlat5v11SUp": -74.779,
  "accSagittalSharp7v11CDown": 80.537,
  "accSagittalFlat7v11CUp": -80.537,
  "accSagittalSharp55CDown": 81.918,
  "accSagittalFlat55CUp": -81.918,
  "accSagittalSharp17CDown": 98.955,
  "accSagittalFlat17CUp": -98.955,
  "accSagittalSharp7v11kDown": 103.997,
  "accSagittalFlat7v11kUp": -103.997,
  "accSagittalSharp7v11kUp": 123.373,
  "accSagittalFlat7v11kDown": -123.373,
  "accSagittalSharp17CUp": 128.415,
  "accSagittalFlat17CDown": -128.415,
  "accSagittalSharp55CUp": 145.452,
  "accSagittalFlat55CDown": -145.452,
  "accSagittalSharp7v11CUp": 146.833,
  "accSagittalFlat7v11CDown": -146.833,
  "accSagittalSharp5v11SUp": 152.591,
  "accSagittalFlat5v11SDown": -152.591,
  "accSagittalDoubleSharp5v11SDown": 188.464,
  "accSagittalDoubleFlat5v11SUp": -188.464,
  "accSagittalDoubleSharp7v11CDown": 194.222,
  "accSagittalDoubleFlat7v11CUp": -194.222,
  "accSagittalDoubleSharp55CDown": 195.603,
  "accSagittalDoubleFlat55CUp": -195.603,
  "accSagittalDoubleSharp17CDown": 212.64,
  "accSagittalDoubleFlat17CUp": -212.64,
  "accSagittalDoubleSharp7v11kDown": 217.682,
  "accSagittalDoubleFlat7v11kUp": -217.682,
  "accidentalDoubleFlatOneArrowDown": -248.88,
[..]
}
```

- Finally, [an XSL script to parse a MusicXML score into an ASCL tuning](https://github.com/infojunkie/musicxml-midi/blob/main/src/xsl/tuning.xsl). The script gathers note+accidental combinations in the MusicXML score, and emits a correctly-formatted tuning file for those combinations. The SMuFL accidentals JSON file above is consulted to obtain the right pitch alteration in case it's missing in the score. The [reusable XSL library `lib-musicxml.xsl`](https://github.com/infojunkie/musicxml-midi/blob/main/src/xsl/lib-musicxml.xsl) does the heavy lifting of computing carried-over and implicit accidentals throughout the score :raised_hands:

## What is `music-i18n`, really?
I keep mentioning `music-i18n` in this post, without defining it. What do I mean by this term?

Just like human languages, I consider music to be a language with many dialects. Pardon the imprecise analogy: My aim is not to dive into linguistics or ethnomusicology. At the moment, and for the most part, existing music software are speaking one specific dialect of music: The Western mainstream dialect, based on 12 tones tuned to specific frequencies and from which a huge edifice of theory and assumptions has been built. Music software followed suit and integrated the theory and assumptions of mainstream Western music down to its deepest layers. It takes significant re-design and re-engineering effort to go back and refactor the many software layers to accommodate other assumptions, or to provide generalizations that fit multiple music dialects, without disrupting the whole software edifice.

Thankfully, music standards today support global music systems to a large extent. To cite some examples that I mentioned above:

- The MIDI Tuning Standard (MTS) allows to reprogram the 128 MIDI keys to any tuning, outside the mainstream 12 tones
- SMuFL is a wonderful W3C standard that extends Unicode with an ever-increasing set of musical symbols from different music cultures, and includes a reference font
- MusicXML supports a wide range of accidentals beyond the mainstream ones, including all SMuFL symbols, both for individual notes and for key signatures

I view `music-i18n` as an umbrella term for any activity that goes towards retrofitting existing music software (and creating more) with the ability to handle non-mainstream music systems, reusing to the fullest the capabilities of open standards, and working on extending those standards when they fall short. Of course, musicians and programmers all over the world routinely engage in `music-i18n` as they attempt to express non-Western musical cultures in software. I find that thinking about this activity holistically helps organize the individual efforts and comprehend its full scope.

## Goals for the coming year
Wow, this was a mouthful! Thank you for reading all the way down. Where am I going from here?

First and foremost, I'll be focusing on completing the Maqamatna work to see it through release. This will validate the work done over the year and provide a valuable new resource to the Arabic music community.

I also want to submit my work on Verovio for inclusion in the mainline. I expect that [my current fork](https://github.com/infojunkie/verovio/pull/2) will need to be divided into smaller patches for submission, and with fairly significant changes before they are accepted. I hope the core maintainers will support my work in this PR :crossed_fingers:

Similarly for [my MusicXML modifications](https://github.com/infojunkie/musicxml/pull/1) to support multiple accidentals and other `music-i18n` elements, I will work on submitting them for inclusion :pray:

When the microtonal dust settles, I hope I can devote some attention to world rhythms. This has always been a personal interest in my music practice, and I hope to express it in software soon :drum:

As always, I hope to hear from interested readers and I welcome all opportunities for collaboration! :saxophone: :handshake:
