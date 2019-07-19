import Vue from 'vue';
import Cookies from 'js-cookie';
import * as CEMountSidebar from '~/sidebar/mount_sidebar';
import { parseBoolean } from '~/lib/utils/common_utils';

import sidebarWeight from './components/weight/sidebar_weight.vue';

import SidebarItemEpic from './components/sidebar_item_epic.vue';
import SidebarItemEpicsSelect from './components/sidebar_item_epics_select.vue';
import SidebarStore from './stores/sidebar_store';

const mountWeightComponent = mediator => {
  const el = document.querySelector('.js-sidebar-weight-entry-point');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      sidebarWeight,
    },
    render: createElement =>
      createElement('sidebar-weight', {
        props: {
          mediator,
        },
      }),
  });
};

const mountEpic = () => {
  const el = document.querySelector('#js-vue-sidebar-item-epic');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      SidebarItemEpic,
    },
    render: createElement => createElement('sidebar-item-epic', {}),
  });
};

const mountEpicsSelect = () => {
  const el = document.querySelector('#js-vue-sidebar-item-epics-select');

  if (!el) return false;

  const { groupId, issueId, epicIssueId, canEdit } = el.dataset;
  const sidebarStore = new SidebarStore();

  return new Vue({
    el,
    components: {
      SidebarItemEpicsSelect,
    },
    render: createElement =>
      createElement('sidebar-item-epics-select', {
        props: {
          sidebarStore,
          groupId: Number(groupId),
          issueId: Number(issueId),
          epicIssueId: Number(epicIssueId),
          canEdit: parseBoolean(canEdit),
        },
      }),
  });
};

export default function mountSidebar(mediator) {
  CEMountSidebar.mountSidebar(mediator);
  mountWeightComponent(mediator);
  if (parseBoolean(Cookies.get('epics_select_dropdown'))) {
    mountEpicsSelect();
  } else {
    mountEpic();
  }
}
