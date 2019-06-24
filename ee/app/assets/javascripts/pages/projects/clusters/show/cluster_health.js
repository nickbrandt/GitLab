import initCeBundle from '~/monitoring/monitoring_bundle';

export default () => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    initCeBundle({
      ...el.dataset,
      showLegend: false,
      showPanels: false,
      forceSmallGraph: true,
      smallEmptyState: true,
      currentEnvironmentName: '',
      environmentsEndpoint: '',
      hasMetrics: true,
    });
  }
};
