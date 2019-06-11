import $ from 'jquery';
import Cookies from 'js-cookie';
import BurndownChart from './burndown_chart';
import BurndownChartData from './burndown_chart_data';
import Flash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__, __ } from '~/locale';

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

        const chart = new BurndownChart({ container, startDate, dueDate });

        let currentView = 'count';
        chart.setData(openIssuesCount, {
          label: s__('BurndownChartLabel|Open issues'),
          animate: true,
        });

        $('.js-burndown-data-selector').on('click', 'button', function switchData() {
          const $this = $(this);
          const show = $this.data('show');
          if (currentView !== show) {
            currentView = show;
            $this
              .removeClass('btn-inverted')
              .siblings()
              .addClass('btn-inverted');
            switch (show) {
              case 'count':
                chart.setData(openIssuesCount, {
                  label: s__('BurndownChartLabel|Open issues'),
                  animate: true,
                });
                break;
              case 'weight':
                chart.setData(openIssuesWeight, {
                  label: s__('BurndownChartLabel|Open issue weight'),
                  animate: true,
                });
                break;
              default:
                break;
            }
          }
        });

        window.addEventListener('resize', () => chart.animateResize(1));
        $(document).on('click', '.js-sidebar-toggle', () => chart.animateResize(2));
      })
      .catch(() => new Flash(__('Error loading burndown chart data')));
  }
};
