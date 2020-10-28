---
layout: post
title: Music blogging
date: 2020-10-08
---
I'm interested in music blogging, to document my journey as a music practicioner. By "music blogging", I mean inserting music snippets within regular blog posts, just like one does with mathematical notation, code snippets, media objects, etc. 

To achieve this, I do the following:
- Write the music in notation software. I use [Musescore](https://musescore.org) because it's open source AND works great :heart:
- Export the snippet into [MusicXML](https://musicxml.com) which is a (de-facto) standard interchange format.
- Import the MusicXML into an online music platform, such as [Musescore](https://musescore.com/infojunkie), [Flat](https://flat.io/karim_ratib), [Noteflight](https://www.noteflight.com/profile/18add9c28a546a47378515d9da5eb66208a169c1). The requirement from these platforms is that they support sharing / embedding snippets, typically via oEmbed or using an HTML embed code.
- Embed the shared music snippet within a blog engine / CMS that supports oEmbed or HTML embed codes. For Jekyll, I use [jekyll_oembed](http://www.jekyll-plugins.com/plugins/jekyll_oembed) for oEmbed and [kramdown GFM parser](https://github.com/kramdown/parser-gfm) to directly paste HTML embed codes within the markdown. 

Here are the results for Scott Joplin's Entertainer, intro section: 

# Musecore 
Using HTML embed code, because [oEmbed seems broken](https://musescore.com/groups/improving-musescore-com/discuss/5077716).

<iframe width="100%" height="394" src="https://musescore.com/user/55682/scores/6383405/embed" frameborder="0" allowfullscreen allow="autoplay; fullscreen"></iframe>

# Flat
Using oEmbed endpoint.

{% oembed https://flat.io/score/5f98dedcdac66f6a161511da-the-entertainer-intro?sharingKey=140d65b4b00e3d28f8ceb9fe9c114600ead0379d6b996a7b0739d63293ddf0f954e5d93b7751b4055aa943bcd444f0bbf34508bf4a8ba05752296ec74adc527b  %}

# Noteflight
Using oEmbed endpoint.

{% oembed https://www.noteflight.com/scores/view/60f7dc9ec8d4a7db487e89f89179af5c0a3a2286 %}

# Conclusion
Visually, the Flat embed is the most appealing to me, because it flows within the page without additional borders, unnecessary scrolling or intrusive chrome. The option to playback at slower speed is appreciated. I wish the snippet name were rendered in their bottom bar.

Because I am interested in ["music localization"]({% post_url 2018-01-05-music-l10n %}), i.e. rendering non-Western music, I need to dig deeper into how well microtones, non-Latin fonts, ethnic instruments, etc. are supported on those platforms.

Happy music blogging :musical_note: