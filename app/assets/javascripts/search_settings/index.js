import Vue from 'vue';
import SearchSettings from './components/search_settings.vue';

const initSearch = ({ el, searchRoot, sectionSelector, onCollapse, onExpand }) =>
  new Vue({
    el,
    mounted() {
      this.$refs.searchSettings.$on('expand', onExpand);
      this.$refs.searchSettings.$on('collapse', onCollapse);
    },
    render: (h) =>
      h(SearchSettings, {
        ref: 'searchSettings',
        props: {
          searchRoot,
          sectionSelector,
        },
      }),
  });

export default initSearch;
