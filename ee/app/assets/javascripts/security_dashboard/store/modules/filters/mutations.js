import * as types from './mutation_types';

export default {
  [types.SET_ALL_FILTERS](state, payload = {}) {
    state.filters = state.filters.map(filter => {
      // If the payload is empty, we fall back to an empty selection
      const selectedOptions = (payload && payload[filter.id]) || [];

      const selection = Array.isArray(selectedOptions)
        ? new Set(selectedOptions)
        : new Set([selectedOptions]);

      // This prevents us from selecting nothing at all
      if (selection.size === 0) {
        selection.add('all');
      }

      return { ...filter, selection };
    });
  },
  [types.SET_FILTER](state, payload) {
    const { filterId, optionId } = payload;
    const activeFilter = state.filters.find(filter => filter.id === filterId);

    if (activeFilter) {
      let selection = new Set(activeFilter.selection);

      if (optionId === 'all') {
        selection = new Set(['all']);
      } else {
        selection.delete('all');
        if (selection.has(optionId)) {
          selection.delete(optionId);
        } else {
          selection.add(optionId);
        }
      }

      // This prevents us from selecting nothing at all
      if (selection.size === 0) {
        selection.add('all');
      }
      activeFilter.selection = selection;
    }
  },
  [types.SET_FILTER_OPTIONS](state, payload) {
    const { filterId, options } = payload;
    state.filters.find(filter => filter.id === filterId).options = options;
  },
};
