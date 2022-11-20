---
layout: post
title: How to prepare your Web application for Web MIDI on Firefox
date: 2022-04-23
---
{% include changelog.html changes="Nov 20, 2022 | OBSOLETE! Firefox no longer requires the complicated process outlined below to enable Web MIDI and now behaves like Chrome does. I am only keeping this post for posterity." %}

In this note, I explain the process of preparing your Web application to use Wed MIDI API on Firefox, because this process is different from Chrome and involves a few more steps that may be counter-intuitive or surprising. I include screenshots and code snippets from my own app.

<!--more-->

After 9 years of waiting, [Web MIDI support has finally landed in Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=836897), as of FF 99. This is great cause for celebration for Web audio developers, as Firefox is the last of the independent Web browsers. Our audio applications no longer need to be crippled on this platform :tada: :notes:

One reason for this long delay was the reluctance of the core Firefox team to open up new potential security holes in the already wide surface of Web APIs. Indeed, Web MIDI allows pages to access MIDI devices on the user's machine, both for reading and writing. The Web MIDI committee [acknowledges the security implications of this API](https://webaudio.github.io/web-midi-api/#security-and-privacy-considerations-of-midi), and [has added explicit gatekeeping measures](https://webaudio.github.io/web-midi-api/#obtaining-access-to-midi-devices) to allow browser makers to choose the level of security they deem appropriate.

In Chrome, calling `navigator.requestMIDIAccess()` checks for an HTTPS connection (or `localhost`) before allowing the usage of the Web MIDI API. In case `navigator.requestMIDIAccess({ sysex: true })` is called, a dialog first prompts the user to grant the application the right to [send SysEx (System Exclusive) MIDI messages](https://blog.landr.com/midi-sysex/).

By contrast, in Firefox 99+, the call to `navigator.requestMIDIAccess()` ALWAYS fails (again, except on `localhost`) until the user has explicitly downloaded and installed a "site permission" add-on that requests the permission to access Web MIDI API on your app's behalf. Once installed, the add-on will automatically prompt the user for this permission.

To make this work, you need to:
- [Request the site permission add-on](https://extensionworkshop.com/documentation/publish/site-permission-add-on/) using your Firefox developer account.

{% include image.html url="/assets/webmidi-addon.jpg" width="100%" %}

- Host the add-on that is generated for you in the same domain as your app, and make it accessible for download - it's a `.xpi` file and a regular `<a href>` tag will do fine.
- Detect a permission error upon calling `navigator.requestMIDIAccess()` and detect that Firefox is the user agent.
- Show a message on your app that the user needs to a) download and install the add-on above, and b) refresh the page once they have installed it and granted the permission to use Web MIDI. Something like this:

{% include image.html url="/assets/webmidi-message.jpg" width="100%" %}

Can your app detect that the permission has been granted to avoid a manual refresh? No, [says the documentation](https://extensionworkshop.com/documentation/publish/site-permission-add-on/#:~:text=However%2C%20there%20is%20no%20alert%20provided%20to%20your%20website%20that%20the%20extension%20has%20been%20installed.%20So%2C%20after%20offering%20the%20add%2Don%20for%20installation%20you%20should%20ask%20the%20user%20to%20try%20granting%20permission%20again.):

> However, there is no alert provided to your website that the extension has been installed. So, after offering the add-on for installation you should ask the user to try granting permission again.

What happens next is out of your control:
- The user downloads and installs the add-on.

{% include image.html url="/assets/webmidi-install-1.jpg" width="100%" %}

- Firefox shows a second prompt to enable Web MIDI, which the user needs to accept as well.

{% include image.html url="/assets/webmidi-install-2.jpg" width="100%" %}

- The user refreshes the app page. This time, the call to `navigator.requestMIDIAccess()` will succeed and Web MIDI will be enabled :clap:

{% include image.html url="/assets/webmidi-outputs.jpg" width="100%" %}

## Initialization code
In my [MusicXML player demo](https://blog.karimratib.me/demos/musicxml/), the initialization code handles 3 conditions related to `navigator.requestMIDIAccess()`:
- The function does not exist, indicating an old browser that does not support Web MIDI at all. MIDI functionality will be disabled in this case.
- A permission error, in which case I check for Firefox user agent and show the add-on download message.
- A successful invocation, in which case Web MIDI is enabled.

```javascript
  if (navigator.requestMIDIAccess) navigator.requestMIDIAccess({ sysex: false })
  .then(midiAccess => {
    document.getElementById('firefox-midi').classList.add('hide');
    // MIDI initialization here...
  }, error => {
    const isFirefox = navigator.userAgent.toLowerCase().indexOf('firefox') > -1;
    if (isFirefox) {
      document.getElementById('firefox-midi').classList.remove('hide');
    }
    console.error(error);
  });
```

## Debugging hints
You will likely need to iterate on your permission-handling logic and user messaging. I've found that a good way is to remove the site permission add-on from `about:addons` (in the "Site Permissions" tab). When you reload your app, you'll be able to restart the permissioning process from scratch.

{% include image.html url="/assets/webmidi-addons.jpg" width="100%" %}

Another way is to remove the "Access MIDI devices with SysEx support" permission from the site settings - note that I was unable to find a way to distinguish between the absence of site permission add-on, versus the user disallowing the use of Web MIDI.

{% include image.html url="/assets/webmidi-permissions.jpg" width="100%" %}

That's it! Happy music coding :saxophone:
