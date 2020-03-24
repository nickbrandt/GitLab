import Vue from 'vue';
import WikiPagesList from './components/wiki_pages_list.vue';

export default el => {
  if (!el) {
    return;
  }

  const { cloneUrl } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(WikiPagesList, {
        props: {
          cloneUrl,
        },
      });
    },
  });
};
