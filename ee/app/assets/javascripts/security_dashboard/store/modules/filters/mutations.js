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
          selected: option.id === optionId,
        }));
      } else {
        activeOptions = activeFilter.options.map(option => {
          if (option.id === 'all') {
            return {
              ...option,
              selected: false,
            };
          }

          if (option.id === optionId) {
            return {
              ...option,
              selected: !option.selected,
            };
          }

          return option;
        });
      }

      // This prevents us from selecting nothing at all
      if (!activeOptions.find(option => option.selected)) {
        activeOptions[0].selected = true;
      }

      activeFilter.options = activeOptions;
    }
  },
};
