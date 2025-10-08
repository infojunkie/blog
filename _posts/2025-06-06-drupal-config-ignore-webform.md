---
layout: post
title: "Drupal 10: Getting Config Ignore and Webform to play nice together"
date: 2025-06-05
category: drupal
description: I describe a technique for ignoring some, not all, webform settings from config sync. This gives flexibility to business users to manage end-user-facing form labels without fully giving up on configuration management. Along the way, I solve a quirk in Config Ignore that prevents from hard-coding its own configuration in <code>settings.php</code>.
image: /assets/ignore-config-ignore.jpg
---
In my role as Systems Architect, I devote a lot of effort to configuration management. In Drupal-land, this means making sure that the site's configuration synchronization runs smoothly and idempotently, across all deployment stages. We've been using a `drush`-based deployment sequence that has served us well across the many sites that we maintain. Here's the magic incantation:
```bash
drush cr; drush updb -y; drush cim -y; drush deploy:hook -y; drush cr;
```
This little sequence allows us to reliably update Drupal core, the site configuration and our own custom modules without running into dependency loops. [Drupal's Configuration API](https://www.drupal.org/docs/drupal-apis/configuration-api) is a very well-designed system that has greatly simplified this process since Drupal 8, especially with its plugin-based architecture that allows contrib modules to fine-tune the process.

For us, the [Config Ignore contrib module](https://www.drupal.org/project/config_ignore) is invaluable because business users typically require control over _some aspects_ the site's configuration, typically when it comes to end-user-facing settings like labels and titles. By using Config Ignore's excellent support for wildcards, individual subkeys and exclusion operator, we have a powerful toolset to give business users what they need.

## Overriding `config_ignore.settings` in `settings.php`
During development, it's common to want to override the official configuration with different settings. The usual approach is to use the `settings.local.php` file with a hard-coded `$config` entry - in our case `$config['config_ignore.settings']`. However, I quickly discovered that these overridden settings don't get picked up by Config Ignore! Here we go, a new debugging dive 🤿... It turns out that [the default Drupal config factory is only consulted if the `config_ignore.settings` entry is NOT present in the sync folder](https://git.drupalcode.org/project/config_ignore/-/blob/149db17d375e78ec79245d08a71a062953dbc8c3/src/EventSubscriber/ConfigIgnoreEventSubscriber.php#L141-155). I am pretty sure this is the opposite of the usual expectation, and I may submit an issue to discuss that. In the meantime, here's a small workaround that will pick up your overridden settings:

```php
// my_custom_module.module
use Drupal\config_ignore\ConfigIgnoreConfig;

/**
 * Implements hook_config_ignore_ignored_alter().
 */
function my_custom_module_config_ignore_ignored_alter(&$ignoreConfig) {
  $override = \Drupal::config('config_ignore.settings');
  if (!empty($override)) {
    try {
      $ignoreConfig = ConfigIgnoreConfig::fromConfig($override);
    }
    catch (\Throwable $e) {
      \Drupal::logger('my_custom_module')->error('Invalid value for config_ignore.settings override. Ignoring.');
    }
  }
}
```
⚠️ BUT! How to _remove_ config entries, instead of adding them? Consider the following `config_ignore.settings.yml` file in your config sync:
```yaml
# config_ignore.settings.yml
mode: simple
ignored_config_entities:
  - mimemail.settings
  - openid_connect.settings
  - 'openid_connect.settings.*'
  - system.maintenance
  - system.performance
  - system.site
  - update.settings
  - 'webform.webform.abilities_quiz:third_party_settings.my_custom_module.*'
  - 'webform.webform.interests_quiz:third_party_settings.my_custom_module.*'
  - 'webform.webform.learning_styles_quiz:third_party_settings.my_custom_module.*'
  - 'webform.webform.multiple_intelligences_quiz:third_party_settings.my_custom_module.*'
  - 'webform.webform.work_preferences_quiz:third_party_settings.my_custom_module.*'
  - 'webform.webform.work_values_quiz:third_party_settings.my_custom_module.*'
```
What happens if you declare the following override in your `settings.local.php`:
```php
// settings.local.php
// INCORRECT VERSION!
$config['config_ignore.settings'] = [
  'mode' => 'simple',
  'ignored_config_entities' => [
    'mimemail.settings',
    'openid_connect.settings',
    'openid_connect.settings.*',
    'system.maintenance',
    'system.performance',
    // 'system.site',
    'update.settings',
    // 'webform.webform.abilities_quiz:third_party_settings.my_custom_module.*',
    // 'webform.webform.interests_quiz:third_party_settings.my_custom_module.*',
    // 'webform.webform.learning_styles_quiz:third_party_settings.my_custom_module.*',
    // 'webform.webform.multiple_intelligences_quiz:third_party_settings.my_custom_module.*',
    // 'webform.webform.work_preferences_quiz:third_party_settings.my_custom_module.*',
    // 'webform.webform.work_values_quiz:third_party_settings.my_custom_module.*'
  ]
];
```
Will `system.site` and the `webform.webform.*` be now kept out of the ignore list? ❌ NO!! As per the module code linked above, the `$config` array is **merged** with the original, resulting in the original bottom keys being kept. In order to truly override the settings, you would write the `$config` array to contain at least as many entries as the original:
```php
// settings.local.php
$config['config_ignore.settings'] = [
  'mode' => 'simple',
  'ignored_config_entities' => [
    'mimemail.settings',
    'openid_connect.settings',
    'openid_connect.settings.*',
    'system.maintenance',
    'system.performance',
    '', // 'system.site',
    'update.settings',
    '', // 'webform.webform.abilities_quiz:third_party_settings.my_custom_module.*',
    '', // 'webform.webform.interests_quiz:third_party_settings.my_custom_module.*',
    '', // 'webform.webform.learning_styles_quiz:third_party_settings.my_custom_module.*',
    '', // 'webform.webform.multiple_intelligences_quiz:third_party_settings.my_custom_module.*',
    '', // 'webform.webform.work_preferences_quiz:third_party_settings.my_custom_module.*',
    '' // 'webform.webform.work_values_quiz:third_party_settings.my_custom_module.*'
  ]
];
```
Now we are correctly overriding Config Ignore settings :tada:

{% include image.html url="/assets/config-ignore-ignore.jpg" width="100%" description="Is that recursive enough for you?" %}

## Ignoring Webform element titles
With this out of the way, let's go back to the initial business requirement: Allowing admin users to modify webform element titles without these changes getting reverted during the next config sync.

Here's what a typical webform config looks like:
```yaml
# webform.webform.interests_quiz.yml
langcode: en
status: open
dependencies:
  module:
    - webformautosave
third_party_settings:
  webformautosave:
    auto_save: true
    auto_save_time: 5000
    optimistic_locking: false
weight: 0
open: null
close: null
uid: 1
template: false
archive: false
id: interests_quiz
title: 'Interests Quiz'
description: ''
categories: {  }
elements: |-
  page_1:
    '#type': webform_wizard_page
    '#title': 'Page 1'
    '#prev_button_label': Back
    '#next_button_label': Next
    i_would_like_to_building_kitchen_cabinets:
      '#type': radios
      '#title': 'I like building kitchen cabinets.'
      '#options': options_interests
      '#category': Realistic
      '#required': true
    i_would_enjoy_laying_brick_or_tile:
      '#type': radios
      '#title': 'I would enjoy laying brick or tile.'
      '#options': options_interests
      '#category': Realistic
      '#required': true
    i_would_like_to_develop_a_new_medicine:
      '#type': radios
      '#title': 'I would like to develop a new medicine.'
      '#options': options_interests
      '#category': Investigative
      '#required': true
[...]
```
As you can see, there's no individual YAML key for each element title - instead, all elements are stored together in the `elements` key, with each element title specified in a `#title` subentry. How to ignore these `#title` entries while keeping the rest of the `elements` under config sync?

I don't know about you, but the thought of hacking Drupal Configuration API + Config Ignore to handle synchronization of array sub-entries does not sound like a productive approach to me. Instead, I decided to reuse Webform's Third Party Settings mechanism to store entries for each element label individually, and apply those labels instead of the originals during rendering. Here's how the webform config would then look:
```yaml
# webform.webform.interests_quiz.yml
langcode: en
status: open
dependencies:
  module:
    - webformautosave
    - my_custom_module # THIS IS NEW
third_party_settings:
  webformautosave:
    auto_save: true
    auto_save_time: 5000
    optimistic_locking: false
  my_custom_module: # THIS IS NEW
    i_would_like_to_building_kitchen_cabinets: 'I REALLY 💙 building kitchen cabinets.'
    i_would_enjoy_laying_brick_or_tile:
    i_would_like_to_develop_a_new_medicine: 'I would like to develop a new medicine and make 💰💰💰.'
weight: 0
open: null
close: null
uid: 1
template: false
archive: false
id: interests_quiz
title: 'Interests Quiz'
description: ''
categories: {  }
elements: |-
  page_1:
    '#type': webform_wizard_page
    '#title': 'Page 1'
    '#prev_button_label': Back
    '#next_button_label': Next
    i_would_like_to_building_kitchen_cabinets:
      '#type': radios
      '#title': 'I like building kitchen cabinets.'
      '#options': options_interests
      '#category': Realistic
      '#required': true
    i_would_enjoy_laying_brick_or_tile:
      '#type': radios
      '#title': 'I would enjoy laying brick or tile.'
      '#options': options_interests
      '#category': Realistic
      '#required': true
    i_would_like_to_develop_a_new_medicine:
      '#type': radios
      '#title': 'I would like to develop a new medicine.'
      '#options': options_interests
      '#category': Investigative
      '#required': true
```
With this in place, it's now trivial to add the third party settings to `config_ignore.settings`, as we've seen above:
```yaml
# config_ignore.settings.yml
mode: simple
ignored_config_entities:
  [..]
  - 'webform.webform.interests_quiz:third_party_settings.my_custom_module.*'
  [..]
```
Here's the code needed to create the new title settings:
```php
// my_custom_module.module

/**
 * Implements hook_webform_third_party_settings_form_alter().
 */
function my_custom_module_webform_third_party_settings_form_alter(array &$form, FormStateInterface $form_state) {
  /** @var \Drupal\webform\WebformInterface $webform */
  $webform = $form_state->getFormObject()->getEntity();

  // Add an entry for the title of each element.
  $questions = array_filter($webform->getElementsInitializedAndFlattened(), some_condition_function);
  foreach ($questions as $key => $question) {
    $form['third_party_settings']['my_custom_module'][$key] = [
      '#type' => 'textfield',
      '#title' => t('Override: @question', ['@question' => $question['#title']]),
      '#required' => false,
      '#default_value' => $webform->getThirdPartySetting('my_custom_module', $key, '')
    ];
  }
}
```
And here's a rudimentary way to display them:
```php
// my_custom_module.module

/**
 * Implements template_preprocess_fieldset().
 */
function my_custom_module_preprocess_fieldset(&$variables) {
  if (isset($variables['element']['#webform'])) {
    /** @var \Drupal\webform\WebformInterface $webform */
    $webform = \Drupal::entityTypeManager()->getStorage('webform')->load($variables['element']['#webform']);

    // Override the element title with the corresponding third party setting.
    $variables['element']['#title'] = $webform->getThirdPartySetting('my_custom_module', $variables['element']['#webform_key'], $variables['element']['#title']);
  }
}
```
{% include image.html url="/assets/config-ignore-webform.png" width="100%" description="The webform with overridden element titles." %}

Et voilà ! Happy site builders and happy business users 👷‍♀️🤝🤵‍♀️
