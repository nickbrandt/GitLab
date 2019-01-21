import state from 'ee/feature_flags/store/modules/index/state';
import mutations from 'ee/feature_flags/store/modules/index/mutations';
import * as types from 'ee/feature_flags/store/modules/index/mutation_types';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getRequestData } from '../../mock_data';

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

    it('should set featureFlags with the given data', () => {
      expect(stateCopy.featureFlags).toEqual(getRequestData.feature_flags);
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
});
