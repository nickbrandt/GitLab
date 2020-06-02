import Vue from 'vue';
import createStore from './store';
import { DASHBOARD_TYPES } from './store/constants';
import ProjectSecurityDashboard from './components/project_security_dashboard.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default () => {
  const securityTab = document.getElementById('js-security-report-app');
  const props = {
    ...securityTab.dataset,
    hasPipelineData: parseBoolean(securityTab.dataset.hasPipelineData),
  };

  if (props.hasPipelineData) {
    Object.assign(props, {
      project: {
        id: props.projectId,
        name: props.projectName,
      },
      triggeredBy: {
        avatarPath: props.userAvatarPath,
        name: props.userName,
        path: props.userPath,
      },
      pipeline: {
        id: parseInt(props.pipelineId, 10),
        created: props.pipelineCreated,
        path: props.pipelinePath,
      },
      commit: {
        id: props.commitId,
        path: props.commitPath,
      },
      branch: {
        id: props.refId,
        path: props.refPath,
      },
    });
  }

  const store = createStore({
    dashboardType: DASHBOARD_TYPES.PROJECT,
  });

  return new Vue({
    el: securityTab,
    store,
    render(createElement) {
      return createElement(ProjectSecurityDashboard, {
        props,
      });
    },
  });
};
