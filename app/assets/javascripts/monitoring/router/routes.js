import DashboardPage from '../pages/dashboard_page.vue';
import PanelBuilder from '../pages/panel_builder_page.vue';

import { BASE_DASHBOARD_PAGE, BUILDER_PAGE } from './constants';

/**
 * Because the cluster health page uses the dashboard
 * app instead the of the dashboard component, hitting
 * `/` route is not possible. Hence using `*` until the
 * health page is refactored.
 * https://gitlab.com/gitlab-org/gitlab/-/issues/221096
 */
export default [
  {
    name: BUILDER_PAGE,
    path: '/builder',
    component: PanelBuilder,
  },
  {
    name: BASE_DASHBOARD_PAGE,
    path: '*',
    component: DashboardPage,
  },
];
