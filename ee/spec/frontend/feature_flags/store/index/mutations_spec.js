import state from 'ee/feature_flags/store/modules/index/state';
import mutations from 'ee/feature_flags/store/modules/index/mutations';
import * as types from 'ee/feature_flags/store/modules/index/mutation_types';
import { mapToScopesViewModel } from 'ee/feature_flags/store/modules/helpers';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getRequestData, rotateData, featureFlag } from '../../mock_data';

describe('Feature flags store Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_FEATURE_FLAGS_ENDPOINT', () => {
    it('should set endpoint', () => {
      mutations[types.SET_FEATURE_FLAGS_ENDPOINT](stateCopy, 'feature_flags.json');

      expect(stateCopy.endpoint).toEqual('feature_flags.json');
    });
  });

  describe('SET_FEATURE_FLAGS_OPTIONS', () => {
    it('should set provided options', () => {
      mutations[types.SET_FEATURE_FLAGS_OPTIONS](stateCopy, { page: '1', scope: 'all' });

      expect(stateCopy.options).toEqual({ page: '1', scope: 'all' });
    });
  });

  describe('SET_INSTANCE_ID_ENDPOINT', () => {
    it('should set provided endpoint', () => {
      mutations[types.SET_INSTANCE_ID_ENDPOINT](stateCopy, 'rotate_token.json');

      expect(stateCopy.rotateEndpoint).toEqual('rotate_token.json');
    });
  });

  describe('SET_INSTANCE_ID', () => {
    it('should set provided token', () => {
      mutations[types.SET_INSTANCE_ID](stateCopy, rotateData.token);

      expect(stateCopy.instanceId).toEqual(rotateData.token);
    });
  });

  describe('REQUEST_FEATURE_FLAGS', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_FEATURE_FLAGS](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_FEATURE_FLAGS_SUCCESS', () => {
    const headers = {
      'x-next-page': '2',
      'x-page': '1',
      'X-Per-Page': '2',
      'X-Prev-Page': '',
      'X-TOTAL': '37',
      'X-Total-Pages': '5',
    };

    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAGS_SUCCESS](stateCopy, { data: getRequestData, headers });
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set featureFlags with the transformed data', () => {
      const expected = getRequestData.feature_flags.map(flag => ({
        ...flag,
        scopes: mapToScopesViewModel(flag.scopes || []),
      }));

      expect(stateCopy.featureFlags).toEqual(expected);
    });

    it('should set count with the given data', () => {
      expect(stateCopy.count).toEqual(getRequestData.count);
    });

    it('should set pagination', () => {
      expect(stateCopy.pageInfo).toEqual(parseIntPagination(normalizeHeaders(headers)));
    });
  });

  describe('RECEIVE_FEATURE_FLAGS_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAGS_ERROR](stateCopy);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });
  });

  describe('REQUEST_ROTATE_INSTANCE_ID', () => {
    beforeEach(() => {
      mutations[types.REQUEST_ROTATE_INSTANCE_ID](stateCopy);
    });

    it('should set isRotating to true', () => {
      expect(stateCopy.isRotating).toBe(true);
    });

    it('should set hasRotateError to false', () => {
      expect(stateCopy.hasRotateError).toBe(false);
    });
  });

  describe('RECEIVE_ROTATE_INSTANCE_ID_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS](stateCopy, { data: rotateData });
    });

    it('should set the instance id to the received data', () => {
      expect(stateCopy.instanceId).toBe(rotateData.token);
    });

    it('should set isRotating to false', () => {
      expect(stateCopy.isRotating).toBe(false);
    });

    it('should set hasRotateError to false', () => {
      expect(stateCopy.hasRotateError).toBe(false);
    });
  });

  describe('RECEIVE_ROTATE_INSTANCE_ID_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ROTATE_INSTANCE_ID_ERROR](stateCopy);
    });

    it('should set isRotating to false', () => {
      expect(stateCopy.isRotating).toBe(false);
    });

    it('should set hasRotateError to true', () => {
      expect(stateCopy.hasRotateError).toBe(true);
    });
  });

  describe('UPDATE_FEATURE_FLAG', () => {
    beforeEach(() => {
      stateCopy.featureFlags = getRequestData.feature_flags.map(flag => ({
        ...flag,
        scopes: mapToScopesViewModel(flag.scopes || []),
      }));
      stateCopy.count = { enabled: 1, disabled: 0 };

      mutations[types.UPDATE_FEATURE_FLAG](stateCopy, {
        ...featureFlag,
        scopes: mapToScopesViewModel(featureFlag.scopes || []),
        active: false,
      });
    });

    it('should update the flag with the matching ID', () => {
      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          scopes: mapToScopesViewModel(featureFlag.scopes || []),
          active: false,
        },
      ]);
    });
    it('should update the enabled count', () => {
      expect(stateCopy.count.enabled).toBe(0);
    });
    it('should update the disabled count', () => {
      expect(stateCopy.count.disabled).toBe(1);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS', () => {
    const runUpdate = (stateCount, flagState, featureFlagUpdateParams) => {
      stateCopy.featureFlags = getRequestData.feature_flags.map(flag => ({
        ...flag,
        ...flagState,
        scopes: mapToScopesViewModel(flag.scopes || []),
      }));
      stateCopy.count = stateCount;

      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](stateCopy, {
        ...featureFlag,
        ...featureFlagUpdateParams,
      });
    };

    it('updates the flag with the matching ID', () => {
      runUpdate({ all: 1, enabled: 1, disabled: 0 }, { active: true }, { active: false });

      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          scopes: mapToScopesViewModel(featureFlag.scopes || []),
          active: false,
        },
      ]);
    });

    it('updates the count data', () => {
      runUpdate({ all: 1, enabled: 1, disabled: 0 }, { active: true }, { active: false });

      expect(stateCopy.count).toEqual({ all: 1, enabled: 0, disabled: 1 });
    });

    describe('when count data does not match up with the number of flags in state', () => {
      it('updates the count data when the flag changes to inactive', () => {
        runUpdate({ all: 4, enabled: 1, disabled: 3 }, { active: true }, { active: false });

        expect(stateCopy.count).toEqual({ all: 4, enabled: 0, disabled: 4 });
      });

      it('updates the count data when the flag changes to active', () => {
        runUpdate({ all: 4, enabled: 1, disabled: 3 }, { active: false }, { active: true });

        expect(stateCopy.count).toEqual({ all: 4, enabled: 2, disabled: 2 });
      });

      it('retains the count data when flag.active does not change', () => {
        runUpdate({ all: 4, enabled: 1, disabled: 3 }, { active: true }, { active: true });

        expect(stateCopy.count).toEqual({ all: 4, enabled: 1, disabled: 3 });
      });
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      stateCopy.featureFlags = getRequestData.feature_flags.map(flag => ({
        ...flag,
        scopes: mapToScopesViewModel(flag.scopes || []),
      }));
      stateCopy.count = { enabled: 1, disabled: 0 };

      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](stateCopy, featureFlag.id);
    });

    it('should update the flag with the matching ID, toggling active', () => {
      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          scopes: mapToScopesViewModel(featureFlag.scopes || []),
          active: false,
        },
      ]);
    });
    it('should update the enabled count', () => {
      expect(stateCopy.count.enabled).toBe(0);
    });
    it('should update the disabled count', () => {
      expect(stateCopy.count.disabled).toBe(1);
    });
  });
});
