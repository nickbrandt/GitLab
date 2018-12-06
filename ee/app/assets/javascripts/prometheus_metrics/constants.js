import PANEL_STATE from '~/prometheus_metrics/constants';

const PANEL_STATE_EE = {
  NO_INTEGRATION: 'no-integration',
};

export default Object.assign({}, PANEL_STATE, PANEL_STATE_EE);
