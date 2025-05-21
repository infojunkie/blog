---
layout: post
title: "Drupal 10: Fix Views Reset button with Big Pipe"
date: 2024-08-29
category: drupal
description: Big Pipe on Drupal 9+ breaks form redirects. In this post, I explain how I fixed it for a specific but common case.
image: /assets/disable-bigpipe.jpg
---
I was **flabbergasted** to discover that Big Pipe breaks the Views Reset button. In fact, Big Pipe breaks **all** form redirects. Not sure how other Drupal devs feel about that, but this was a big smh moment for me. Just imagine the collective time wasted debugging one's code until one associates this failure to a core module bug!! :facepalm:

Now that my rant's over, let's get into the technical details of this story.

## Detecting the bug
The tell-tale sign that you hit this bug is when you enable the Reset button on a view's exposed form, and instead of resetting the view filters, you get a blank page. The log says something like:
```
Drupal\Core\Form\EnforcedResponseException: in Drupal\Core\Form\FormBuilder->buildForm() (line 357 of /var/www/html/web/core/lib/Drupal/Core/Form/FormBuilder.php)
#0 /var/www/html/web/core/modules/views/src/Plugin/views/exposed_form/ExposedFormPluginBase.php(134): Drupal\Core\Form\FormBuilder->buildForm()
#1 /var/www/html/web/core/modules/views/src/ViewExecutable.php(1243): Drupal\views\Plugin\views\exposed_form\ExposedFormPluginBase->renderExposedForm()
```

## Solution 1: Applying the patch
The [relevant bug report](https://www.drupal.org/project/drupal/issues/3304746) has a patch that worked for me. I had to apply the patch manually to Drupal 9.x (please, don't shoot me because I'm not in charge of our Drupal update schedule!!) but the code changes are exactly the same.

When you apply this patch, the Reset button works again. But clumsily: First, you see the URL changing to your current filters followed by `&op=Reset`, then the browser redirects to the page's bare URL, thereby resetting the filters. This is of course a consequence of using Big Pipe, which optimizes page rendering by returning all cached blocks first, and deferring uncacheable blocks to be requested by the front-end. A marvel of engineering by **Wim Leers**! Still, the flickering leaves to be desired.

In my case, this particular view is the principal component of the page, so I feel OK disabling Big Pipe for just this page if at all possible. But how?

## Solution 2a: Disable Big Pipe for a specific route
The standard approach to disabling Big Pipe is to inject the setting `_no_big_pipe: TRUE` in the options of the relevant route. If your page's route is unique, then all you need is to follow the official guide on [altering existing routes](https://www.drupal.org/docs/drupal-apis/routing-system/altering-existing-routes-and-adding-new-routes-based-on-dynamic-ones#s-altering-existing-routes). Specifically, for a view page, the route is of the form `view.view_id.page_id`. So you would have something like the following:
```php
  protected function alterRoutes(RouteCollection $collection) {

    // Disable Big Pipe for my view.
    if ($route = $collection->get('view.view_id.page_id')) {
      $route->setOption('_no_big_pipe', TRUE);
    }

  }
```

But in my case, the view is a block that's embedded in a node page. I cannot simply alter the route `entity.node.canonical`, because this would disable it on 99% of the site!!

{% include image.html url="/assets/disable-bigpipe.jpg" width="100%" description="What do you mean, my memes are obsolete??" %}

# Solution 2b: Disable Big Pipe for a specific URL
I turned to good old [Stack Overflow (technically, Drupal Answers)](https://drupal.stackexchange.com/q/320680/767) to query the hive-mind. Thanks to the ever-helpful and super-knowledgeable **4uk4** for his suggestion! Although I ended up taking a different approach, I will remember that I can override parameterized routes with specific ones because this will surely come in handy in the future.

The approach I ended up following is based on Wim Leer's [Big Pipe Strategy demo](https://git.drupalcode.org/project/big_pipe_demo), where he catches every request in real-time and decides whether to return the Big Pipe placeholders or to ignore them. In my case, instead of examining the request's query arguments for a specific "disable" signal, I compare the URI itself with the target page's URL:
```php
  public function processPlaceholders(array $placeholders) {

    // Ignore Big Pipe for my page URL.
    $current_uri = \Drupal::request()->getRequestUri();
    if (str_starts_with($current_uri, '/path/to/page-to-ignore')) {
      return [];
    }

    return $this->bigPipeStrategy->processPlaceholders($placeholders);
  }
```
Et voilà ! Another bug bites the dust.
