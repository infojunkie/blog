---
layout: page
title: demos
permalink: /demos/
---
Here are some music demos that I am proud-ish to exhibit. Click a screenshot to open the demo page.

<div class="grid-wrapper">

    {% include demo.html url="https://blog.karimratib.me/demos/musicxml/" image="irealpro-musicxml" alt="iReal Pro to MusicXML" title="A demo app for converting iReal Pro leadsheets into MusicXML and rendering them as playable sheet music." %}

    {% include demo.html url="https://blog.karimratib.me/demos/sheetplayer/" image="sheet-player" alt="Sheet Player" title="A demo app using Web Audio, Web MIDI and music engraving to create playable sheet music. Includes non-Western tunings as a bonus!" %}

    {% include demo.html url="https://blog.karimratib.me/demos/drumkit/" image="drumkit" alt="Drumkit" title="A demo app for an offline-first, mobile-based percussion instrument. UI was borrowed from elsewhere but the functionality and code were completely rewritten." %}

    {% include demo.html url="https://blog.karimratib.me/demos/sheetdex/" image="sheetdex" alt="Sheetdex" title="A sheet music index created from various online sources." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/rhythm-diagram" image="rhythm-diagram" alt="Rhythm Diagram" title="An Observable notebook to visualize rhythms as circular diagrams." %}

    {% include demo.html url="https://observablehq.com/@infojunkie/tuning-diagram" image="tuning-diagram" alt="Tuning Diagram" title="An Observable notebook to visualize tunings as circular diagrams." %}

</div>

{% if site.isso.path %}
    {% include isso.html %}
{% endif %}
