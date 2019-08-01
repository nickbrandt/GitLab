import filterState from 'ee/analytics/productivity_analytics/store/modules/filters/state';

const resetStore = store => {
  const newState = {
    filters: filterState(),
  };

  store.replaceState(newState);
};

export default resetStore;
