---
layout: post
title: Music blogging
date: 2020-10-08
---
I'm interested in music blogging, to document my journey as a music practicioner. By "music blogging", I mean inserting music snippets within regular blog posts, just like one does with mathematical notation, code snippets, media objects, etc.

To achieve this, I do the following:
- Write the music in notation software. I use [MuseScore](https://musescore.org) because it's open source AND works great :heart:
- Export the snippet into [MusicXML](https://musicxml.com) which is a (de-facto) standard interchange format.
- Import the MusicXML into an online music platform, such as [MuseScore.com](https://musescore.com/infojunkie), [Flat](https://flat.io/karim_ratib), [Soundslice](https://www.soundslice.com/users/kratib/), [Noteflight](https://www.noteflight.com/profile/18add9c28a546a47378515d9da5eb66208a169c1). The requirement from these platforms is that they support sharing / embedding snippets, typically via oEmbed or using an HTML embed code.
- Embed the shared music snippet within a blog engine / CMS that supports oEmbed or HTML embed codes. For Jekyll, I use [ruby-oembed](https://github.com/ruby-oembed/ruby-oembed) + a [custom tag plugin](https://github.com/infojunkie/blog/blob/master/_plugins/oembed.rb) for oEmbed and [kramdown GFM parser](https://github.com/kramdown/parser-gfm) to directly paste HTML embed codes within the markdown.

Here are the results for Scott Joplin's Entertainer, intro section:

# Musecore
Using HTML embed code, because [oEmbed endpoint is broken](https://musescore.com/groups/improving-musescore-com/discuss/5077716).

<iframe width="100%" height="394" src="https://musescore.com/user/55682/scores/6383405/embed" frameborder="0" allowfullscreen allow="autoplay; fullscreen"></iframe>

# Flat
Using HTML embed code, because oEmbed endpoint is broken.

<iframe src="https://flat.io/embed/5f98dedcdac66f6a161511da" height="450" width="750" frameBorder="0" allowfullscreen></iframe>

# Soundslice
Using HTML embed code, because oEmbed is a paid feature.

 <iframe src="https://www.soundslice.com/slices/vWsfc/embed-channelpost/" width="100%" height="320" frameBorder="0"></iframe>

# Noteflight
Using oEmbed endpoint.

{% oembed https://www.noteflight.com/scores/view/fc73c762b41c4b5f10a28f582464e11a0c7a651b %}

# Conclusion
Visually, the Flat embed is the most appealing to me, because it flows within the page without additional borders, unnecessary scrolling or intrusive chrome. The option to playback at slower speed is appreciated. I wish the snippet name were rendered in their bottom bar.

However, a killer feature that MuseScore.com offers is _chord playback_ on top of the melody. This is very useful to quickly hear and evaluate the specified harmony as the melodic theme is being played. In addition, MuseScore (the music engraver) exports [chord information to MusicXML format](https://www.musicxml.com/tutorial/chord-symbols-diagrams/chord-symbols/), which ensures that other platforms receive the information.

Because I am interested in ["music localization"]({% post_url 2018-01-05-music-l10n %}), i.e. rendering non-Western musics, I need to dig deeper into how well microtones, non-Latin fonts, ethnic instruments, etc. are supported on those platforms.

Happy music blogging :musical_note: