import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './stores';
import mrEditModule from './stores/modules/mr_edit';
import MrEditApp from './components/mr_edit/app.vue';
import TargetBranchAlertApp from './components/target_branch_alert/app.vue';

Vue.use(Vuex);

export default function mountMrEdit(el) {
  if (!el) {
    return null;
  }

  const store = createStore(mrEditModule(), {
    ...el.dataset,
    prefix: 'mr-edit',
    canEdit: parseBoolean(el.dataset.canEdit),
    allowMultiRule: parseBoolean(el.dataset.allowMultiRule),
  });

  const targetBranchAlertElement = document.getElementById('js-target-branch-alert');

  const mountTargetBranchAlert = () =>
    new Vue({
      el: targetBranchAlertElement,
      store,
      render(h) {
        return h(TargetBranchAlertApp);
      },
    });

  const mountApprovalInput = () =>
    new Vue({
      el,
      store,
      render(h) {
        return h(MrEditApp);
      },
    });

  return {
    mountApprovalInput,
    mountTargetBranchAlert,
  };
}
