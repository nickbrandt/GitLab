import state from 'ee/feature_flags/store/modules/index/state';
import mutations from 'ee/feature_flags/store/modules/index/mutations';
import * as types from 'ee/feature_flags/store/modules/index/mutation_types';
import { mapToScopesViewModel } from 'ee/feature_flags/store/modules/helpers';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getRequestData, rotateData } from '../../mock_data';

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
      const expected = getRequestData.feature_flags.map(f => ({
        ...f,
        scopes: mapToScopesViewModel(f.scopes || []),
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
});
