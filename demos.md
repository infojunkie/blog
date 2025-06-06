---
layout: page
title: music
permalink: /demos/
---
Here are some music demos that I am proud-ish to exhibit. Click a screenshot to open the demo page.

<div class="grid-wrapper">

    {% include demo.html url="https://blog.karimratib.me/demos/musicxml/" image="musicxml-player" alt="MusicXML Player" title="A demo app for a reusable component that converts MusicXML scores into playable sheet music, using Web Audio and Web MIDI. Additional support for: iReal Pro, microtonality." %}

    {% include demo.html url="https://blog.karimratib.me/demos/chirp/" image="chirp" alt="ChiRP" title="A simple app to convert an iReal Pro playlist into MusicXML and MIDI files that can be downloaded as a zip package to your computer." %}

    {% include demo.html url="https://blog.karimratib.me/demos/drumkit/" image="drumkit" alt="Drumkit" title="A demo app for an offline-first, mobile-based percussion instrument. UI was borrowed from elsewhere but the functionality and code were completely rewritten." %}

    {% include demo.html url="/musicxml/" image="musicxml-schema" alt="MusicXML Schema" title="A one-page rendition of the MusicXML schema implemented using an XSD-to-HTML transformation script, itself written in XSL." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/rhythm-diagram" image="rhythm-diagram" alt="Rhythm Diagram" title="An Observable notebook to visualize rhythms as circular diagrams." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/tuning-diagram" image="tuning-diagram" alt="Tuning Diagram" title="An Observable notebook to visualize tunings as circular diagrams." %}

</div>

{% if site.isso.path %}
    {% include isso.html %}
{% endif %}
