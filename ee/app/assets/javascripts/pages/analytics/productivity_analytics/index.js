import initProductivityAnalyticsApp from 'ee/analytics/productivity_analytics';

document.addEventListener('DOMContentLoaded', () => {
  const containerEl = document.getElementById('js-productivity-analytics-container');

  initProductivityAnalyticsApp(containerEl);
});
