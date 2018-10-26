import Vue from 'vue';
import NewEpicApp from './components/new_epic.vue';

export default () => {
  const el = document.querySelector('#new-epic-app');

  if (el) {
    const props = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        'new-epic-app': NewEpicApp,
      },
      render: createElement =>
        createElement('new-epic-app', {
          props,
        }),
    });
  }
};
