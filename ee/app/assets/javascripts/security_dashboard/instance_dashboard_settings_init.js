import Vue from 'vue';
import UnavailableState from './components/unavailable_state.vue';

export default el => {
  return new Vue({
    el,
    render(createElement) {
      return createElement(UnavailableState, {
        props: {
          link: el.dataset.dashboardDocumentation,
          svgPath: el.dataset.emptyStateSvgPath,
        },
      });
    },
  });
};
