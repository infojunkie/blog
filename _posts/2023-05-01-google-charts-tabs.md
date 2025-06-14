---
layout: post
title: "Drupal 9: Fixing Google Charts rendering in tabbed pages"
date: 2023-05-01
category: drupal
description: In which I describe a fix to a long-standing bug with Google Charts rendering inside hidden divs. This bug affects charts that are rendered in Boostrap tabs that are not active.
---
Google Charts has a [long-standing, known issue rendering correctly in hidden divs](https://stackoverflow.com/search?q=google+charts+hidden). This caused us much head scratching and debugging hours before we even landed on the correct diagnosis: a chart that renders correctly on the [Charts API Example page](https://git.drupalcode.org/project/charts/-/tree/5.0.x/modules/charts_api_example) does not work inside a tab! Oh, the joys of programming sometimes.

Once diagnosed, the fix was obvious: Detect that a tab is selected to refresh the charts contained therein. The following JavaScript file can be added to your theme as is and should handle the standard Bootstrap tabs (it also fixes the window resize event handling). It does depend on a small patch made to the [`charts_google` module](https://git.drupalcode.org/project/charts/-/tree/5.0.x/modules/charts_google), to avoid leaking memory when the graph is redrawn:
```javascript
(function ($, Drupal, once) {
  ("use strict");

  function redrawGoogleChart(element) {
    const contents = new Drupal.Charts.Contents();
    const chartId = element.id;
    if (Drupal.googleCharts.charts.hasOwnProperty(chartId)) {
      Drupal.googleCharts.charts[chartId].clearChart();
    }
    const dataAttributes = contents.getData(chartId);
    Drupal.googleCharts.drawChart(chartId, dataAttributes['visualization'], dataAttributes['data'], dataAttributes['options'])();
  }

  Drupal.behaviors.redrawGoogleCharts = {
    attach: function (context, settings) {
      $('.nav-link', context).on('shown.bs.tab', function (e) {
        if (Drupal.Charts && Drupal.googleCharts) {
          $('.charts-google', $(e.target).attr('data-bs-target')).each(function () {
            if (this.dataset.hasOwnProperty('chart')) {
              redrawGoogleChart(this);
            }
          });
        }
      });

      window.addEventListener('resize', function () {
        if (Drupal.Charts && Drupal.googleCharts) {
          Drupal.googleCharts.waitForFinalEvent(function () {
            $('.charts-google').each(function () {
              if (this.dataset.hasOwnProperty('chart')) {
                redrawGoogleChart(this);
              }
            });
          }, 200, 'google-charts-redraw');
        }
      });
    },
  };

})(jQuery, Drupal, once);
```
```patch
diff --git a/modules/charts_google/js/charts_google.js b/modules/charts_google/js/charts_google.js
index f7abe81..76143bc 100755
--- a/modules/charts_google/js/charts_google.js
+++ b/modules/charts_google/js/charts_google.js
@@ -6,7 +6,7 @@

   'use strict';

-  Drupal.googleCharts = Drupal.googleCharts || {charts: []};
+  Drupal.googleCharts = Drupal.googleCharts || {charts: {}};

   /**
    * Behavior to initialize Google Charts.
@@ -122,6 +122,7 @@
         options['colorAxis'] = {colors: colors};
       }
       chart.draw(data, options);
+      Drupal.googleCharts.charts[chartId] = chart;
     };
   };
```
