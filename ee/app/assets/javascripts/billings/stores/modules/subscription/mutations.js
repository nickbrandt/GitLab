import Vue from 'vue';
import * as types from './mutation_types';
import { USAGE_ROW_INDEX, BILLING_ROW_INDEX } from '../../../constants';
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

    state.plan = plan;

    /*
     * Update column values for billing and usage row.
     * We iterate over the rows within the state
     * and update only the column's value property in the state
     * with the data we received from the API for the given column
     */
    [USAGE_ROW_INDEX, BILLING_ROW_INDEX].forEach(rowIdx => {
      const currentRow = state.rows[rowIdx];
      currentRow.columns.forEach(currentCol => {
        if (rowIdx === USAGE_ROW_INDEX) {
          Vue.set(currentCol, 'value', usage[currentCol.id]);
        } else if (rowIdx === BILLING_ROW_INDEX) {
          Vue.set(currentCol, 'value', billing[currentCol.id]);
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
