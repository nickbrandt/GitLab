/* eslint-disable no-new */
import Vue from 'vue';
import NotebookViewer from './notebook_viewer.vue';

export default () => {
  const el = document.getElementById('js-notebook-viewer');

  new Vue({
    el,
    render(createElement) {
      return createElement(NotebookViewer, {
        props: {
          endpoint: el.dataset.endpoint,
        },
      });
    },
  });
};
