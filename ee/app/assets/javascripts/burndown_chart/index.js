import Vue from 'vue';
import $ from 'jquery';
import Cookies from 'js-cookie';
import BurnCharts from './components/burn_charts.vue';
import BurndownChartData from './burn_chart_data';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default () => {
  // handle hint dismissal
  const hint = $('.burndown-hint');
  hint.on('click', '.dismiss-icon', () => {
    hint.hide();
    Cookies.set('hide_burndown_message', 'true');
  });

  // generate burndown chart (if data available)
  const container = '.burndown-chart';
  const $chartEl = $(container);

  if ($chartEl.length) {
    const startDate = $chartEl.data('startDate');
    const dueDate = $chartEl.data('dueDate');
    const milestoneId = $chartEl.data('milestoneId');
    const burndownEventsPath = $chartEl.data('burndownEventsPath');
    const burnupEventsPath = $chartEl.data('burnupEventsPath');

    const fetchData = [axios.get(burndownEventsPath)];

    if (gon.features.burnupCharts) {
      fetchData.push(axios.get(burnupEventsPath));
    }

    Promise.all(fetchData)
      .then(([burndownResponse, burnupResponse]) => {
        const burndownEvents = burndownResponse.data;
        const burndownChartData = new BurndownChartData(
          burndownEvents,
          startDate,
          dueDate,
        ).generateBurndownTimeseries();

        const burnupEvents = burnupResponse?.data || [];

        const { burnupScope } =
          new BurndownChartData(burnupEvents, startDate, dueDate).generateBurnupTimeseries({
            milestoneId,
          }) || {};

        const openIssuesCount = burndownChartData.map(d => [d[0], d[1]]);
        const openIssuesWeight = burndownChartData.map(d => [d[0], d[2]]);

        return new Vue({
          el: container,
          components: {
            BurnCharts,
          },
          render(createElement) {
            return createElement('burn-charts', {
              props: {
                startDate,
                dueDate,
                openIssuesCount,
                openIssuesWeight,
                burnupScope,
              },
            });
          },
        });
      })
      .catch(() => {
        createFlash(__('Error loading burndown chart data'));
      });
  }
};
