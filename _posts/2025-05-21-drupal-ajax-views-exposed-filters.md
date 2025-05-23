---
layout: post
title: "Drupal 10: Fix AJAX-related error with Views exposed forms"
date: 2025-05-21
category: drupal
description: Enabling AJAX callbacks on Views exposed forms causes a cryptic error that "the uploaded file likely exceeded the maximum file size". In this post, I explain why this happens, and present a functioning workaround.
image: /assets/what-me-entitled.jpg
---
I don't mind fixing the bugs that I or my team introduce into our codebase - those bugs are expected and par for the course. But bugs in Drupal core are totally unacceptable!! /s

{% include image.html url="/assets/what-me-entitled.jpg" width="100%" description="In reality, these blog posts are just excuses for me to make more silly memes." %}

This one was pretty confusing. I needed to dynamically update a drop-down every time a "parent" drop-down changed (think 2-level taxonomy vocabulary), which is a [well-documented feature in the Forms API](https://www.drupal.org/docs/develop/drupal-apis/javascript-api/ajax-forms). In a nutshell, the parent element gets an `#ajax` callback that is called upon user interaction, and that returns the updated child element from the `$form` structure. The Drupal AJAX frontend code takes care of replacing the child element in the HTML form. Neat and simple. In my case, though, I needed this behaviour in a Views exposed form, and that's when the trouble started. When changing the parent element, the callback was not being called, and instead, an unrelated error was displayed, saying `An unrecoverable error occurred. The uploaded file likely exceeded the maximum file size (XXX) that this server supports`.

{% include image.html url="/assets/views-ajax-exception.gif" width="100%" description="Hi Drupal, which uploaded file are you talking about?" %}

Fortunately, I was able to find [an existing issue](https://www.drupal.org/project/drupal/issues/2658718) (submitted in Jan 2016 :sob:) which was useful to confirm I was not vastly misunderstanding the problem. The workarounds mentioned in this ticket did not work for me, though, so I had to keep digging on my own. Here's the result of my analysis:

## Why this error?
The displayed error has absolutely nothing to do with the situation I was facing: There's no uploaded file at play, and there's not even a `POST`'ed form, since the AJAX request uses the `GET` method. To find the source of an error, I usually start by locating the text of the error in the codebase and work backwards up the call stack - in this case, it is thrown by `FormAjaxSubscriber::onException` which is itself triggered by [`FormBuilder::buildForm`](https://api.drupal.org/api/drupal/core%21lib%21Drupal%21Core%21Form%21FormBuilder.php/function/FormBuilder%3A%3AbuildForm/10) under an unexpected condition:

```php
    // In case the post request exceeds the configured allowed size
    // (post_max_size), the post request is potentially broken. Add some
    // protection against that and at the same time have a nice error message.
    if ($ajax_form_request && !$request->get('form_id')) {
        throw new BrokenPostRequestException($this->getFileUploadMaxSize());
    }
```
I don't know about you, but to me the condition of a missing `form_id` seems unrelated to a file limit issue. By examining the AJAX `GET` request in the browser, I was able to verify that no `form_id` query argument is actually sent - which means that further down this function, the form builder will be unable to find the form object that should be built. Looks like a legitimate error and the AJAX frontend seems to be at fault.

## The workaround needed a workaround
At this point, I had the choice of debugging and fixing the [Drupal AJAX frontend code](https://git.drupalcode.org/project/drupal/-/blob/10.5.x/core/misc/ajax.js), or find a workaround that would allow me to keep working on my business feature. Although I am a firm believer that we should allocate some of our professional time to contribute to the open source software that we use, this seemed a deeper dive than I could afford at that point. Instead, I opted for the most generic workaround that I could reuse in similar future scenarios. Here's what I came with:

The general idea is to simply send the missing `form_id` in the AJAX request. The [Form API `#ajax` properties](https://www.drupal.org/docs/develop/drupal-apis/javascript-api/ajax-forms#s-full-list-of-available-ajax-properties) helpfully include a customizable `url` entry, so I decided to augment the current URL with the `form_id` query argument. Something like that, maybe?
```php
function my_module_form_views_exposed_form_alter(&$form, FormStateInterface $form_state, $form_id) {
    // DANGER: THIS WILL NOT WORK!
    $uri = \Drupal\Component\Utility\UrlHelper::parse(\Drupal::request()->getRequestUri());
    $uri['query']['form_id'] = $form['#id'];
    $uri['query']['ajax_form'] = 1;
    $form['my_parent_element']['#ajax'] = [
      'callback' => 'my_parent_element_callback',
      'wrapper' => 'my-parent-element-container',
      'url' => Url::fromUri('internal:' . $uri['path'], ['query' => $uri['query'], 'fragment' => $uri['fragment']]),
    ];
}
```
If only things were that simple! This did not work - the AJAX request kept missing ALL query arguments after this change. How on earth could `URL` options get ignored?? More hours, more digging revealed [this code deep inside `RenderElementBase::preRenderAjaxForm`](https://git.drupalcode.org/project/drupal/-/blob/10.5.x/core/lib/Drupal/Core/Render/Element/RenderElementBase.php#L381-388) - someone decided to overwrite the incoming URL options with those from another key THAT IS NOT EVEN DOCUMENTED :angry: - I'm sure it seemed like a good idea at the time and I've edited the documentation to reflect this quirk :angel:

So the final code looks like:
```php
function my_module_form_views_exposed_form_alter(&$form, FormStateInterface $form_state, $form_id) {
    // Override the AJAX request to include `form_id` and `ajax_form`.
    $uri = \Drupal\Component\Utility\UrlHelper::parse(\Drupal::request()->getRequestUri());
    $uri['query']['form_id'] = $form['#id'];
    $uri['query']['ajax_form'] = 1;
    $form['my_parent_element']['#ajax'] = [
      'callback' => 'my_parent_element_callback',
      'wrapper' => 'my-parent-element-container',
      'url' => Url::fromUri('internal:' . $uri['path']),
      'options' => ['query' => $uri['query'], 'fragment' => $uri['fragment']]
    ];
}
```

And this, my friends, is how I fixed the file size limit error that occurs on AJAXified Views exposed form elements :tada:

## Sober concluding thoughts
In a codebase as large as Drupal's, it is normal to expect inconsistencies and edge cases. Since this is the second issue that involves Views exposed forms (the first one being an [unwanted interaction with Big Pipe]({% post_url 2024-08-29-drupal-bigpipe-reset %})), I am now expecting more bugs to emanate from this area - namely, the intersection between Views exposed forms and advanced Drupal features. I wonder if anyone's done an analysis of open Drupal issues to find clusters of bugs based on Drupal core components or recurring keywords.

In this particular case, the error that Drupal reports is not only useless, it is actively misleading. This is not particularly unusual either, as error handling is notoriously one of the harder aspects of programming, and much [virtual ink has been spilled to try to make sense of it](https://www.google.com/search?q=error+handling+in+software+development). What should be reported to the user? What should be logged? What should be handled silently? As a software architect who interacts a lot with business users, I can tell you that core Drupal has its own share of confusing and unhelpful error messages. The most egregious one for me is the infamous message `An illegal choice has been detected. Please contact the site administrator.` which only serves to confuse users but offers them no help. In our own software process, I make sure to review the errors thrown by the developers and ask myself the following questions in each case:

- **UX (User eXperience)**: Should end users see an error, a warning, or should the UI keep functioning silently? What information will best help end users to accomplish their task at hand?
- **DX (Developer eXperience)**: Should site builders see an error, a warning, or should the application keep functioning silently? What information will best help site builders to develop the application?
- **DevOps**: Should system engineers see an error, a warning, or should the system keep functioning silently? What information will best help system engineers to manage the site's operation?

The detail about the `URL` options being overridden by an undocumented `['#ajax']['options']` key not only illustrates the difficulty of keeping documentation in sync with the code, but also the importance of thinking about DX when designing APIs, to minimize surprises and inconsistencies which directly translate to bugs or wasted effort.

In the spirit of contributing back, I [documented my workaround in the original issue](https://www.drupal.org/project/drupal/issues/2658718#comment-16099799) and updated the AJAX Forms documentation accordingly - hoping it will prevent further unnecessary hair pulling!
