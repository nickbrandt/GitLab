import Vue from 'vue';
import $ from 'jquery';
import Cookies from 'js-cookie';
import BurnCharts from './components/burn_charts.vue';
import BurndownChartData from './burndown_chart_data';
import Flash from '~/flash';
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
    const burndownEventsPath = $chartEl.data('burndownEventsPath');

    axios
      .get(burndownEventsPath)
      .then(response => {
        const burndownEvents = response.data;
        const chartData = new BurndownChartData(burndownEvents, startDate, dueDate).generate();

        const openIssuesCount = chartData.map(d => [d[0], d[1]]);
        const openIssuesWeight = chartData.map(d => [d[0], d[2]]);

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
              },
            });
          },
        });
      })
      .catch(() => new Flash(__('Error loading burndown chart data')));
  }
};
