import { tableSortOrder } from './../../../constants';

export const sortIcon = state => tableSortOrder[state.sortOrder].icon;

export const sortTooltipTitle = state => tableSortOrder[state.sortOrder].title;

export const sortFieldDropdownLabel = state => state.sortFields[state.sortField];

export const getColumnOptions = state =>
  Object.keys(state.sortFields)
    .filter(key => key !== 'time_to_merge')
    .reduce((obj, key) => {
      const result = { ...obj, [key]: state.sortFields[key] };
      return result;
    }, {});

export const columnMetricLabel = (state, getters) => getters.getColumnOptions[state.columnMetric];

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
