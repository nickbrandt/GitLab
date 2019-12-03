import Vue from 'vue';
import createRouter from 'ee/security_dashboard/store/router';
import projectSelector from 'ee/security_dashboard/store/plugins/project_selector';
import syncWithRouter from 'ee/security_dashboard/store/plugins/sync_with_router';
import createStore from 'ee/security_dashboard/store';
import InstanceSecurityDashboard from 'ee/security_dashboard/components/instance_security_dashboard.vue';

if (gon.features && gon.features.securityDashboard) {
  document.addEventListener('DOMContentLoaded', () => {
    const el = document.querySelector('#js-security');
    const {
      dashboardDocumentation,
      emptyStateSvgPath,
      emptyDashboardStateSvgPath,
      projectAddEndpoint,
      projectListEndpoint,
      vulnerabilitiesCountEndpoint,
      vulnerabilitiesEndpoint,
      vulnerabilitiesHistoryEndpoint,
      vulnerabilityFeedbackHelpPath,
    } = el.dataset;
    const router = createRouter();
    const store = createStore({ plugins: [projectSelector, syncWithRouter(router)] });

    return new Vue({
      el,
      router,
      store,
      components: {
        InstanceSecurityDashboard,
      },
      render(createElement) {
        return createElement(InstanceSecurityDashboard, {
          props: {
            dashboardDocumentation,
            emptyStateSvgPath,
            emptyDashboardStateSvgPath,
            projectAddEndpoint,
            projectListEndpoint,
            vulnerabilitiesCountEndpoint,
            vulnerabilitiesEndpoint,
            vulnerabilitiesHistoryEndpoint,
            vulnerabilityFeedbackHelpPath,
          },
        });
      },
    });
  });
}
