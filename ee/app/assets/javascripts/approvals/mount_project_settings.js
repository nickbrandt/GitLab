import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './stores';
import projectSettingsModule from './stores/modules/project_settings';
import ProjectSettingsApp from './components/project_settings/app.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(Vuex);

export default function mountProjectSettingsApprovals(el) {
  if (!el) {
    return null;
  }

  const store = createStore(projectSettingsModule(), {
    ...el.dataset,
    prefix: 'project-settings',
    allowMultiRule: parseBoolean(el.dataset.allowMultiRule),
  });

  return new Vue({
    el,
    store,
    render(h) {
      return h(ProjectSettingsApp);
    },
  });
}
