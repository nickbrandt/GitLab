import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoNodeFormApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-node-form');

  return new Vue({
    el,
    components: {
      GeoNodeFormApp,
    },

    render(createElement) {
      return createElement('geo-node-form-app');
    },
  });
};
