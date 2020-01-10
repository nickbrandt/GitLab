import { INVALID_CURRENT_ENVIRONMENT_NAME } from '../../../constants';
import { getTimeWindowConfig } from './utils';

export const currentEnvironmentName = ({ currentEnvironmentId, environments }) => {
  const environment = environments.find(({ id }) => id === currentEnvironmentId);
  return environment ? environment.name : INVALID_CURRENT_ENVIRONMENT_NAME;
};

export const currentTimeWindowName = ({ currentTimeWindow }) =>
  getTimeWindowConfig(currentTimeWindow).name;

export const hasHistory = ({ wafStatistics }) =>
  Boolean(wafStatistics.history.nominal.length || wafStatistics.history.anomalous.length);
