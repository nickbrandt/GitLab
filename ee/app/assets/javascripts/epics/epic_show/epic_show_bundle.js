import Vue from 'vue';
import Cookies from 'js-cookie';
import bp from '~/breakpoints';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EpicShowApp from './components/epic_show_app.vue';

export default () => {
  const el = document.querySelector('#epic-show-app');
  const metaData = convertObjectPropsToCamelCase(JSON.parse(el.dataset.meta), { deep: true });
  const initialData = JSON.parse(el.dataset.initial);

  // Collapse the sidebar on mobile screens by default
  const bpBreakpoint = bp.getBreakpointSize();
  if (bpBreakpoint === 'xs' || bpBreakpoint === 'sm') {
    Cookies.set('collapsed_gutter', true);
  }

  // TODO remove once API provides proper data
  initialData.epicLinksEndpoint = '/';
  metaData.parentEpic = {
    id: 7,
    title: 'Epic with out of range end date',
    url: '/groups/gitlab-org/-/epics/7',
    human_readable_timestamp: '<strong>30</strong> days remaining',
    human_readable_end_date: 'Dec 28, 2018',
  };

  const props = Object.assign({}, initialData, metaData, el.dataset);

  return new Vue({
    el,
    components: {
      'epic-show-app': EpicShowApp,
    },
    render: createElement =>
      createElement('epic-show-app', {
        props,
      }),
  });
};
