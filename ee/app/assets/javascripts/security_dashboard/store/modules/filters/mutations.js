import * as types from './mutation_types';

export default {
  [types.SET_FILTER](state, payload) {
    const { filterId, optionId } = payload;
    const activeFilter = state.filters.find(filter => filter.id === filterId);

    if (activeFilter) {
      let activeOptions;

      if (optionId === 'all') {
        activeOptions = activeFilter.options.map(option => ({
          ...option,
          selected: option.id === 'all',
        }));
      } else {
        activeOptions = activeFilter.options.map(option => {
          const selected =
            option.id === optionId ? !option.selected : option.selected && option.id !== 'all';

          return {
            ...option,
            selected,
          };
        });
      }

      activeFilter.options = activeOptions;
    }
  },
};
