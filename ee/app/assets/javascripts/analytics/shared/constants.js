export const dateFormats = {
  isoDate: 'yyyy-mm-dd',
  defaultDate: 'mmm d, yyyy',
  defaultDateTime: 'mmm d, yyyy h:MMtt',
};

export const scatterChartLineProps = {
  default: {
    type: 'line',
    showSymbol: false,
    // By default zlevel is 2 for all series types.
    // By increasing the zlevel to 3 we make sure that the trendline gets drawn in front of the dots in the chart.
    zlevel: 3,
  },
};

export const LAST_ACTIVITY_AT = 'last_activity_at';
