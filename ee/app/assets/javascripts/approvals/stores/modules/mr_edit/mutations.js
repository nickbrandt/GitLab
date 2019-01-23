import _ from 'underscore';
import base from '../base/mutations';
import * as types from './mutation_types';

const seedNew = rule => ({
  ...rule,
  isNew: true,
  id: _.uniqueId('new'),
});

export default {
  ...base,
  [types.SET_APPROVAL_SETTINGS](state, settings) {
    base[types.SET_APPROVAL_SETTINGS](state, {
      ...settings,
      rules: settings.rules.map(x => (x.id ? x : seedNew(x))),
    });
  },
  [types.DELETE_RULE](state, id) {
    const idx = _.findIndex(state.rules, x => x.id === id);

    if (idx < 0) {
      return;
    }

    const rule = state.rules[idx];

    // Keep track of rules we need to submit that are deleted
    if (!rule.isNew) {
      state.rulesToDelete.push(rule.id);
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
    const rules = _.isArray(rule) ? rule : [rule];

    state.rules = state.rules.concat(rules.map(seedNew));
  },
  [types.SET_FALLBACK_RULE](state, fallback) {
    state.fallbackApprovalsRequired = fallback.approvalsRequired;
  },
};
