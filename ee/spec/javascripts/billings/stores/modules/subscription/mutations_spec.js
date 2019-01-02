import createState from 'ee/billings/stores/modules/subscription/state';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import mutations from 'ee/billings/stores/modules/subscription/mutations';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import mockData from '../../../mock_data';

describe('subscription module mutations', () => {
  describe('SET_NAMESPACE_ID', () => {
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

    describe('Gold subscription', () => {
      beforeEach(() => {
        state = createState();
        payload = mockData.gold;
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
        const usageRow = state.tables.default.rows[0];
        const data = convertObjectPropsToCamelCase(payload, { deep: true });
        usageRow.columns.forEach(column => {
          expect(column.value).toBe(data.usage[column.id]);
        });
      });

      it('should set the column values on the "Billing" row', () => {
        const billingRow = state.tables.default.rows[1];
        const data = convertObjectPropsToCamelCase(payload, { deep: true });
        billingRow.columns.forEach(column => {
          expect(column.value).toBe(data.billing[column.id]);
        });
      });
    });

    describe('Free plan', () => {
      beforeEach(() => {
        state = createState();
        payload = mockData.free;
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

      it('should populate "subscriptionStartDate" from "billings row" correctly', () => {
        const usageRow = state.tables.free.rows[0];
        const data = convertObjectPropsToCamelCase(payload, { deep: true });
        usageRow.columns.forEach(column => {
          if (column.id === 'subscriptionStartDate') {
            expect(column.value).toBe(data.billing.subscriptionStartDate);
          }
        });
      });
    });

    describe('Gold trial', () => {
      beforeEach(() => {
        state = createState();
        payload = mockData.trial;
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

      it('should populate "subscriptionStartDate" and "subscriptionEndDate" from "billings row" correctly', () => {
        const usageRow = state.tables.trial.rows[0];
        const data = convertObjectPropsToCamelCase(payload, { deep: true });
        usageRow.columns.forEach(column => {
          if (column.id === 'subscriptionStartDate') {
            expect(column.value).toBe(data.billing.subscriptionStartDate);
          } else if (column.id === 'subscriptionEndDate') {
            expect(column.value).toBe(data.billing.subscriptionEndDate);
          }
        });
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
