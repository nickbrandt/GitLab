import initCycleAnalytics from '~/cycle_analytics/cycle_analytics_bundle';
import initCycleAnalyticsApp from 'ee/analytics/cycle_analytics/index';
import { parseBoolean } from '~/lib/utils/common_utils';
import Cookies from 'js-cookie';

if (parseBoolean(Cookies.get('cycle_analytics_app'))) {
  document.addEventListener('DOMContentLoaded', initCycleAnalyticsApp);
} else {
  document.addEventListener('DOMContentLoaded', initCycleAnalytics);
}
