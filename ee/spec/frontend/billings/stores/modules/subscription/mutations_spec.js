import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createState from 'ee/billings/stores/modules/subscription/state';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import mutations from 'ee/billings/stores/modules/subscription/mutations';
import subscription from './mock_subscription.json';
import tables from './mock_tables.json';

describe('EE billings subscription module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_NAMESPACE_ID, () => {
    it('sets namespaceId', () => {
      const expectedNamespaceId = 'test';

      expect(state.namespaceId).toBeNull();

      mutations[types.SET_NAMESPACE_ID](state, expectedNamespaceId);

      expect(state.namespaceId).toBe(expectedNamespaceId);
    });
  });

  describe(types.REQUEST_SUBSCRIPTION, () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_SUBSCRIPTION](state);

      expect(state.isLoading).toBeTruthy();
    });

    it('sets hasError to false', () => {
      mutations[types.REQUEST_SUBSCRIPTION](state);

      expect(state.hasError).toBeFalsy();
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_SUBSCRIPTION_SUCCESS](state, subscription);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('sets plan', () => {
      const { plan } = convertObjectPropsToCamelCase(subscription, { deep: true });

      expect(state.plan).toEqual(plan);
    });

    it('sets tables', () => {
      const expectedTables = convertObjectPropsToCamelCase(tables, { deep: true });

      expect(state.tables).toEqual(expectedTables);
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_SUBSCRIPTION_ERROR](state);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('sets hasError to true', () => {
      expect(state.hasError).toBeTruthy();
    });
  });
});
