import { barChartOptions } from '~/lib/utils/chart_utils';

const defaultOptions = barChartOptions();

export const CHART_OPTNS = {
  ...defaultOptions,
  scaleOverlay: true,
  pointHitDetectionRadius: 2,
  barValueSpacing: 2,
  scales: {
    xAxes: [
      {
        gridLines: {
          display: false,
          drawBorder: false,
          color: 'transparent',
        },
      },
    ],
    yAxes: [
      {
        gridLines: {
          color: '#DFDFDF',
          drawBorder: false,
          drawTicks: false,
        },
        ticks: {
          padding: 10,
        },
      },
    ],
  },
};

export const CHART_COLORS = {
  backgroundColor: 'rgba(31,120,209,0.1)',
  borderColor: 'rgba(31,120,209,1)',
  hoverBackgroundColor: 'rgba(31,120,209,0.3)',
  borderWidth: 1,
};
