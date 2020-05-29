import Vue from 'vue';
import ToggleEpicsSwimlanes from './components/toggle_epics_swimlanes.vue';
import store from '~/boards/stores';

export default () =>
  new Vue({
    el: document.getElementById('js-board-epics-swimlanes-toggle'),
    components: {
      ToggleEpicsSwimlanes,
    },
    store,
    render(createElement) {
      return createElement(ToggleEpicsSwimlanes);
    },
  });
