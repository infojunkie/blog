---
layout: post
title: Visualizing musical tunings in the browser
date: 2021-01-07
---
One of my recurring intellectual joys is to learn about the deep connections between music and mathematics. About a decade ago, I discovered the amazing work of Gareth Loy, ["Musimathics: The Mathematical Foundations of Music"](http://www.musimathics.com/), a generous 2-volume overview of the mathematics and physics underlying many different aspects of music, from waves to sampling to psychoacoustics. For a non-mathematician like myself, the maths in this book are easy to follow and the intuition is greatly helped by examples and diagrams. It has become one of my favourite references, which I've had the pleasure to offer to many of my similarly-minded friends.

{% include image.html description="Musimathics Volume I" url="/assets/LOY_revised_1.gif" %}
{% include image.html description="Musimathics Volume II" url="/assets/LOY_revised_2.gif" %}

One of the first subjects that fascinated me is the chapter about "Musical Scales, Tuning, and Intonation" that explains the evolution of tunings and temperaments from Pythagorean tuning to the contemporary 12-tet temperament, and sent me through the rabbit hole of microtonality experiments across musical cultures and scholarships. Growing up in Egypt, where microtonal maqam music has a long and established history, I especially appreciated the book's mathematical exposition that allowed me to grasp the logical foundations of this musical culture.

It is in this spirit that I was motivated to create a [Web Audio experiment](https://blog.karimratib.me/demos/sheetplayer/) that allows to play back various pieces in different temperaments - including recreating a [historical microtonal tuning described by a 19th century French musicologist](https://play.google.com/store/books/details?id=JUv0AAAAMAAJ) who studied Egyptian music practices at the time of Napoleon's French campaign in Egypt, before the temperament of this region's music was ["normalized" (to use a gentle euphemism) to 24-tet in a famous music congress in Cairo in 1932](https://en.wikipedia.org/wiki/Cairo_Congress_of_Arab_Music).

Later, I came across beautiful circular diagrams representing musical rhythms, as pioneered by [Godfried Toussaint](http://cgm.cs.mcgill.ca/~godfried/rhythm-and-mathematics.html). The clarity of these diagrams inspired me to recreate them for musical tunings, which also exhibit periodicity. Here's the result, using Mike Bostock's excellent Observable platform. You can click the notes to hear them:

<iframe width="100%" height="700" frameborder="0"
  src="https://observablehq.com/embed/@infojunkie/tuning-diagram?cell=chart"></iframe>

## A quick introduction to the mathematics of tuning

The mathematics of tuning are quite simple, once the historical details are abstracted. Essentially, the problem that musicians face is to choose satisfactory intervals for their scales, that are a) pleasing to the ear, b) flexible enough to express the various emotions/meanings that they want to convey, and c) feasible on their instruments. Musical cultures and scholars have solved this problem in different ways over the ages, but some features are largely invariant and constitute the building blocks of most scales, because of the psychoacoustic features of human perception.

Musical pitches (notes) are specific frequencies of sound waves. Regardless of specific frequency, though, the human ear perceives **ratios** of frequencies (called _intervals_) as meaningful: given a note played at frequency _f_, the human ear will perceive another note at frequency _2f_ as being equivalent in quality (called _chroma_) albeit of higher pitch. The ratio 2:1 is called the _octave_ and constitutes the first invariant when building up a scale. Another significant ratio is the _perfect fifth_ (ratio 3:2) which most musical cultures use as a point of tension in the melodic development, which tends to eventually resolve to the root _tonic_ note.

From these humble beginnings, the puzzle of building up a scale is then to populate the interval 2:1 with many more notes that enrich the possibilities of musical expression. I refer the interested reader to the book above for an in-depth exposition, or indeed the multitude of online resources devoted to this subject (starting of course with the [relevant Wikipedia article](https://en.wikipedia.org/wiki/Music_and_mathematics)).

In the tuning diagram above, the circle represents a single octave, on which the intervals of various tunings are laid out according to their ratios. For example, the modern Western 12-tet temperament is made up of 12 equal intervals, each equal to the 12th root of 2 (i.e. <span class="nowrap"><sup style="margin-right: -0.5em; vertical-align: 0.8em;">12</sup>√<span style="border-top:1px solid; padding:0 0.1em;">2</span></span>) which yields a perfect octave (<span class="nowrap">2<sup>&#8203;<sup>12</sup>⁄<sub>12</sub></sup></span> = 2), and an acceptably approximate fifth (within the [psychoacoustic limits of human perception](https://en.wikipedia.org/wiki/Just-noticeable_difference#Music_production_applications)).

## Future work

I have encapsulated and enhanced the tuning logic of my Web Audio experiment into [a JavaScript library](https://github.com/infojunkie/scalextric) which can be reused in Web applications. The plan is to use this library in my ongoing project to create a musician's online notebook, which will allow for musical scores to be annotated and manipulated to enhance one's understanding and expressive possibilities.
