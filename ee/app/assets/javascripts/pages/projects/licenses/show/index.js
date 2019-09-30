import Vue from 'vue';
import { __ } from '~/locale';

if (gon.features && gon.features.licensesList) {
  document.addEventListener(
    'DOMContentLoaded',
    () =>
      new Vue({
        el: '#js-licenses-app',
        render(createElement) {
          return createElement('h1', __('License Compliance'));
        },
      }),
  );
}
