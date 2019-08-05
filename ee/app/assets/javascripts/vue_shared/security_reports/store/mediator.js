import * as types from './mutation_types';

const updateIssueActionsMap = {
  sast: 'sast/updateVulnerability',
  dependency_scanning: 'dependencyScanning/updateVulnerability',
  container_scanning: 'updateContainerScanningIssue',
  dast: 'updateDastIssue',
};

export default function configureMediator(store) {
  store.subscribe(({ type, payload }) => {
    switch (type) {
      case types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS:
        if (updateIssueActionsMap[payload.category]) {
          store.dispatch(updateIssueActionsMap[payload.category], payload);
        }
        break;
      default:
    }
  });
}
