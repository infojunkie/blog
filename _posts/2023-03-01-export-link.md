---
layout: post
title: "Drupal 9: Showing an export link for each manually updated configuration item"
date: 2023-03-01
category: drupal
description: In which I describe how to add an export link to each out-of-sync configuration item right on the main Configuration synchronization page.
---
The [Configuration API](https://www.drupal.org/docs/drupal-apis/configuration-api) is by far the best surprise I got about Drupal 9. Finally, a core system that is robust enough to hold any configuration set reliably, and extensible enough for contrib modules. Back in Drupal 7, maintaining a consistent configuration across stages had been the bane of my existence, and I was delighted to find it was now a solved problem.

One minor wrinkle I found is related to the scenario of admin users wanting to update the configs that are otherwise stored in source control:
- Admin changes a permission on stage PROD via Admin UI
- Devops makes a code deployment on stages DEV => TEST => PROD
- The permission change is lost, unless Admin exports the updated permission config and hands it to Devops before deployment

To support this scenario, Admin needs to go to **Configuration synchronization** `/admin/config/development/configuration`, examine the changed items, then head over to **Single export** `/admin/config/development/configuration/single/export` and GUESS how the name that they saw on the previous screen maps to a given configuration type/name pair on this one. User-unfriendly and error-prone!

My quick solution was to add an **Export config** action for each updated item in the **Configuration synchronization** screen, as per the attached screenshot. This was feasible to implement because [the **Single export** route actually accepts a specific configuration type/name pair](https://git.drupalcode.org/project/drupal/-/blob/9.5.3/core/modules/config/config.routing.yml#L56-64), which my code computes given the configuration item (and that was not terribly straightforward). Now Admin can easily export all modified configuration items without any guesswork!

{% include image.html url="/assets/drupal-config-sync.png" width="100%" %}

{% include image.html url="/assets/drupal-config-export.png" width="100%" %}

```php
use Drupal\Core\Config\Entity\ConfigEntityInterface;

/**
 * Implements hook_form_FORM_ID_alter() for config_admin_import_form.
 *
 * Show export link for each modified config item.
 */
function MYMODULE_form_config_admin_import_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  $configs = [];
  foreach (\Drupal::service('entity_type.manager')->getDefinitions() as $entity_type => $definition) {
    if ($definition->entityClassImplements(ConfigEntityInterface::class)) {
      $entity_storage = \Drupal::service('entity_type.manager')->getStorage($entity_type);
      foreach ($entity_storage->loadMultiple() as $entity) {
        $configs[$definition->getConfigPrefix() . '.' . $entity->id()] = [
          'config_type' => $entity_type,
          'config_name' => $entity->id(),
        ];
      }
    }
  }

  $collection = '';
  $config_change_type = 'update';
  if (!empty($form[$collection][$config_change_type]['list']['#rows'])) {
    foreach ($form[$collection][$config_change_type]['list']['#rows'] as &$config_change) {
      $config_item = $config_change['name'];

      if (array_key_exists($config_item, $configs)) {
        $config_type = $configs[$config_item]['config_type'];
        $config_name = $configs[$config_item]['config_name'];
      }
      else {
        $config_type = 'system.simple';
        $config_name = $config_item;
      }

      $config_change['operations']['data']['#links']['export'] = [
        'title' => t('Export config'),
        'url' => Url::fromRoute('config.export_single', [
          'config_type' => $config_type,
          'config_name' => $config_name,
        ]),
      ];
    }
  }
}
```
