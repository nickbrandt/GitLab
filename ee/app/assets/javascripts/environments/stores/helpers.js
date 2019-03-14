import { CLUSTER_TYPE } from '~/clusters/constants';

/**
 * Deploy boards are EE only.
 *
 * @param {Object} environment
 * @returns {Object}
 */
// eslint-disable-next-line import/prefer-default-export
export const setDeployBoard = (oldEnvironmentState, environment) => {
  let parsedEnvironment = environment;
  if (
    environment.size === 1 &&
    environment.rollout_status &&
    environment.cluster_type !== CLUSTER_TYPE.GROUP
  ) {
    parsedEnvironment = Object.assign({}, environment, {
      hasDeployBoard: true,
      isDeployBoardVisible:
        oldEnvironmentState.isDeployBoardVisible === false
          ? oldEnvironmentState.isDeployBoardVisible
          : true,
      deployBoardData:
        environment.rollout_status.status === 'found' ? environment.rollout_status : {},
      isLoadingDeployBoard: environment.rollout_status.status === 'loading',
      isEmptyDeployBoard: environment.rollout_status.status === 'not_found',
    });
  }
  return parsedEnvironment;
};
