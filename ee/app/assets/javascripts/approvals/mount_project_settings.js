import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './stores';
import projectSettingsModule from './stores/modules/project_settings';
import ProjectSettingsApp from './components/project_settings/app.vue';

Vue.use(Vuex);

export default function mountProjectSettingsApprovals(el) {
  if (!el) {
    return null;
  }

  const store = createStore(projectSettingsModule(), {
    prefix: 'project-settings',
    ...el.dataset,
  });

  return new Vue({
    el,
    store,
    render(h) {
      return h(ProjectSettingsApp);
    },
  });
}
