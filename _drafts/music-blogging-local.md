---
layout: post
title: "Music blogging, part 2: Engraving engines"
date: 2021-01-28
---

In [a previous post]({% post_url 2020-10-08-music-blogging %}), I examined ways to embed music snippets on Web pages, using online music platforms that offer embedding capabilities. In this post, I dig a little deeper into the world of Web-based music engraving engines, still with the aim to produce a simple solution that can be used by bloggers and other producers of Web-based musical content.

First, let's define some criteria for evaluating the engines we'll be reviewing. Given the use-case above, we expect the music engines to offer the following required or optional capabilities:

#### Render music fragments on a Web page
Regardless of the input method, the engine should render music fragments on a Web page, respecting the typical requirements of blog presentations:
- Block layouting and sizing
- Content styling
- Responsiveness to various device form factors

#### Provide simple input for the music fragments
Since the use case is about rendering short musical fragments, as opposed to complete scores, the input mechanism for the music content should be simplified for rapid editing, without sacrificing too much expressive power.

### VexTab
[VexTab](https://github.com/0xfe/vextab) is a text-based music script built upon [VexFlow](https://github.com/0xfe/vexflow), one of the main open source Web music engravers.

<div class="vextab-auto" width="800">
options space=20
tabstave notation=true key=E time=4/4

notes :8 (14/1.11/3) $B7$ (16/1.13/3) (12/1.9/3) :q (9/1.6/3) $F♯m7$ :8 (11/1.8/3) :q (7/1.0/2) $B7$ |
notes :8 (2/1.4/4)   $B7$ (4/1.1/3)   (0/1.2/4)  :q (2/2.4/5) $F♯m7$ :8 (4/2.1/4)  :q (0/2.2/5) $B7$ |
notes :8 (4/4.2/6)   $B7$ (6/4.4/6)   (2/4.0/6)  :q 4/5 $F♯m7$ :8 1/4 $B7$ 0/4 4/5 |
notes :w 2/5 $B7$
</div>

<script src="https://cdn.jsdelivr.net/npm/vextab@3.0.6/dist/main.prod.min.js"></script>

### OpenSheetMusicDisplay
OpenSheetMusicDisplay (OSMD) is a MusicXML parser that is also built upon VexFlow.

{% include osmd.html url="/assets/entertainer.musicxml" id="osmd1" %}

<script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@0.9.2/build/opensheetmusicdisplay.min.js"></script>

### music21j

<div class="music21 tinyNotation">
  4/4 kE F#8 G#8 E8 C#4 D#8 B4
  F#8 G#8 E8 C#4 D#8 B4
  F#8 G#8 E8 C#4 D#8 D8 C#8
  B1
</div>

<script src="https://cdn.jsdelivr.net/npm/music21j@0.9.58/releases/music21.debug.js"></script>

### abcjs

<div id="abcjs"></div>
<div id="abcjs-audio"></div>

<script src="https://www.abcjs.net/abcjs_basic_5.9.1-min.js"></script>
<link href="https://www.abcjs.net/abcjs-audio.css" media="all" rel="stylesheet" type="text/css" />

<script>
var cooleys = 'X:1\nT: Cooley\'s\nM: 4/4\nL: 1/8\nR: reel\nK: Emin\nD2|:"Em"EB{c}BA B2 EB|~B2 AB dBAG|"D"FDAD BDAD|FDAD dAFD|\n"Em"EBBA B2 EB|B2 AB defg|"D"afe^c dBAF|1"Em"DEFD E2 D2:|2"Em"DEFD E2 gf||\n|:"Em"eB B2 efge|eB B2 gedB|"D"A2 FA DAFA|A2 FA defg|\n"Em"eB B2 eBgB|eB B2 defg|"D"afe^c dBAF|1"Em"DEFD E2 gf:|2"Em"DEFD E4|]\n';

document.addEventListener('DOMContentLoaded', (event) => {
  var visualObj = ABCJS.renderAbc('abcjs', cooleys)[0];
  var synthControl = new ABCJS.synth.SynthController();
  synthControl.load("#abcjs-audio", null, {displayRestart: true, displayPlay: true, displayProgress: true});
  synthControl.setTune(visualObj, false);
})
</script>

### Verovio

<div id="verovio"></div>

<script>
document.addEventListener('DOMContentLoaded', (event) => {
  var vrvToolkit = new verovio.toolkit();
  /* Load the file using HTTP GET */
  fetch("https://www.verovio.org/examples/hello-world/Haydn_StringQuartet_Op1_No1-p1.mei").then( (response) => {
    response.text().then( (text) => {
    var svg = vrvToolkit.renderData(text, {});
    $("#verovio").html(svg);
  })});
});
</script>

<script src="http://www.verovio.org/javascript/latest/verovio-toolkit.js"></script>

### alphaTab

<script src="https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/alphaTab.min.js"></script>

<div id="alphaTab" data-tex="true">
\title "Hello alphaTab"
.
:4 0.6 1.6 3.6 0.5 2.5 3.5 0.4 2.4 |
   3.4 0.3 2.3 0.2 1.2 3.2 0.1 1.1 |
   3.1.1
</div>

<script type="text/javascript">
document.addEventListener('DOMContentLoaded', (event) => {
  const element = document.getElementById('alphaTab');
  const api = new alphaTab.AlphaTabApi(element);
});
</script>
