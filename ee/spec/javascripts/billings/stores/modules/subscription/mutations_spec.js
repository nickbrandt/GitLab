import createState from 'ee/billings/stores/modules/subscription/state';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import mutations from 'ee/billings/stores/modules/subscription/mutations';
import { USAGE_ROW_INDEX, BILLING_ROW_INDEX } from 'ee/billings/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mockData from './data/mock_data_subscription.json';

describe('subscription module mutations', () => {
  describe('SET_PNAMESPACE_ID', () => {
    it('should set "namespaceId" to "1"', () => {
      const state = createState();
      const namespaceId = '1';

      mutations[types.SET_NAMESPACE_ID](state, namespaceId);

      expect(state.namespaceId).toEqual(namespaceId);
    });
  });

  describe('REQUEST_SUBSCRIPTION', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.REQUEST_SUBSCRIPTION](state);
    });

    it('should set "isLoading" to "true", ()', () => {
      expect(state.isLoading).toBeTruthy();
    });
  });

  describe('RECEIVE_SUBSCRIPTION_SUCCESS', () => {
    let payload;
    let state;

    beforeEach(() => {
      payload = mockData;
      state = createState();
      mutations[types.RECEIVE_SUBSCRIPTION_SUCCESS](state, payload);
    });

    it('should set "isLoading" to "false"', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('should set "plan" attributes', () => {
      expect(state.plan.code).toBe(payload.plan.code);
      expect(state.plan.name).toBe(payload.plan.name);
      expect(state.plan.trial).toBe(payload.plan.trial);
    });

    it('should set the column values on the "Usage" row', () => {
      const usageRow = state.rows[USAGE_ROW_INDEX];
      const data = convertObjectPropsToCamelCase(payload, { deep: true });
      usageRow.columns.forEach(column => {
        expect(column.value).toBe(data.usage[column.id]);
      });
    });

    it('should set the column values on the "Billing" row', () => {
      const billingow = state.rows[BILLING_ROW_INDEX];
      const data = convertObjectPropsToCamelCase(payload, { deep: true });
      billingow.columns.forEach(column => {
        expect(column.value).toBe(data.billing[column.id]);
      });
    });
  });

  describe('RECEIVE_SUBSCRIPTION_ERROR', () => {
    let state;

    beforeEach(() => {
      state = createState();
      mutations[types.RECEIVE_SUBSCRIPTION_ERROR](state);
    });

    it('should set "isLoading" to "false"', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('should set "hasError" to "true"', () => {
      expect(state.hasError).toBeTruthy();
    });
  });
});
