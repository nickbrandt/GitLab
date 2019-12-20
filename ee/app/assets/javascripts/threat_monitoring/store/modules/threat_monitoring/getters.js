import { INVALID_CURRENT_ENVIRONMENT_NAME } from './constants';

// eslint-disable-next-line import/prefer-default-export
export const currentEnvironmentName = ({ currentEnvironmentId, environments }) => {
  const environment = environments.find(({ id }) => id === currentEnvironmentId);
  return environment ? environment.name : INVALID_CURRENT_ENVIRONMENT_NAME;
};
