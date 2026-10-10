---
layout: page
title: music
permalink: /demos/
---
Here are some music demos that I am proud-ish to exhibit. Click a screenshot to open the project page.

<div class="grid-wrapper">

    {% include demo.html url="https://blog.karimratib.me/demos/musicxml/" image="musicxml-player" alt="MusicXML Player" title="A demo app for a reusable component that converts MusicXML scores into playable sheet music, using Web Audio and Web MIDI. Additional support for: iReal Pro, microtonality." %}

    {% include demo.html url="https://musicxml.formats.music/" image="musicxml-astro" alt="MusicXML W3C" title="The official MusicXML website, rewritten using Astro static site generator, co-written with <a href='https://davidmatthew.ie/'>David Matthew</a>." %}

    {% include demo.html url="https://blog.karimratib.me/demos/mma-ts/" image="mma-ts" alt="mma-ts" title="A demo app of the TypeScript port of the Musical MIDI Accompaniment Python engine, co-written with Claude Code." %}

    {% include demo.html url="https://blog.karimratib.me/demos/chirp/" image="chirp" alt="ChiRP" title="A simple app to convert an iReal Pro playlist into MusicXML and MIDI files that can be downloaded as a zip package to your computer." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/rhythm-diagram" image="rhythm-diagram" alt="Rhythm Diagram" title="An Observable notebook to visualize rhythms as circular diagrams." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/tuning-diagram" image="tuning-diagram" alt="Tuning Diagram" title="An Observable notebook to visualize tunings as circular diagrams." %}

</div>

{% if site.isso.path %}
    {% include isso.html %}
{% endif %}
