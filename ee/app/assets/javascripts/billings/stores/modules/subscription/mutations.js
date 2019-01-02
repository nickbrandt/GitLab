import Vue from 'vue';
import { TABLE_TYPE_DEFAULT, TABLE_TYPE_FREE, TABLE_TYPE_TRIAL } from '../../../constants';
import * as types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  [types.SET_NAMESPACE_ID](state, payload) {
    state.namespaceId = payload;
  },

  [types.REQUEST_SUBSCRIPTION](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.RECEIVE_SUBSCRIPTION_SUCCESS](state, payload) {
    const data = convertObjectPropsToCamelCase(payload, { deep: true });
    const { plan, usage, billing } = data;
    let tableKey = TABLE_TYPE_DEFAULT;

    state.plan = plan;

    if (state.plan.code === null) {
      tableKey = TABLE_TYPE_FREE;
    } else if (state.plan.trial) {
      tableKey = TABLE_TYPE_TRIAL;
    }

    state.tables[tableKey].rows.forEach(row => {
      row.columns.forEach(col => {
        if (Object.prototype.hasOwnProperty.call(usage, col.id)) {
          Vue.set(col, 'value', usage[col.id]);
        } else if (Object.prototype.hasOwnProperty.call(billing, col.id)) {
          Vue.set(col, 'value', billing[col.id]);
        }
      });
    });

    state.isLoading = false;
  },

  [types.RECEIVE_SUBSCRIPTION_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
};
