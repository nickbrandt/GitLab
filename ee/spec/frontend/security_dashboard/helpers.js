import vulnerabilitiesState from 'ee/security_dashboard/store/modules/vulnerabilities/state';
import filterState from 'ee/security_dashboard/store/modules/filters/state';

// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  const newState = {
    vulnerabilities: vulnerabilitiesState(),
    filters: filterState(),
  };
  store.replaceState(newState);
};
