import _ from 'underscore';
import base from '../base/mutations';
import * as types from './mutation_types';

export default {
  ...base,
  [types.DELETE_RULE](state, id) {
    const idx = _.findIndex(state.rules, x => x.id === id);

    if (idx < 0) {
      return;
    }

    state.rules.splice(idx, 1);
  },
  [types.PUT_RULE](state, { id, ...newRule }) {
    const idx = _.findIndex(state.rules, x => x.id === id);

    if (idx < 0) {
      return;
    }

    const rule = { ...state.rules[idx], ...newRule };
    state.rules.splice(idx, 1, rule);
  },
  [types.POST_RULE](state, rule) {
    state.rules.push(rule);
  },
};
