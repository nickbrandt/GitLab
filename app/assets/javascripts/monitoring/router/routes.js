import DashboardPage from '../pages/dashboard_page.vue';

import { BASE_DASHBOARD_PAGE, CUSTOM_DASHBOARD_PAGE } from './constants';

export default [
  {
    name: BASE_DASHBOARD_PAGE,
    path: '/',
    component: DashboardPage,
    children: [
      {
        name: CUSTOM_DASHBOARD_PAGE,
        path: '/d/:dashboard',
        component: DashboardPage,
      },
    ],
  },
];
