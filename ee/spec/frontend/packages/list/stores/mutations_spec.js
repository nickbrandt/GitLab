import * as commonUtils from '~/lib/utils/common_utils';
import mutations from 'ee/packages/list/stores/mutations';
import * as types from 'ee/packages/list/stores/mutation_types';
import createState from 'ee/packages/list/stores/state';
import { npmPackage, mavenPackage } from '../../mock_data';

describe('Mutations Registry Store', () => {
  let mockState;
  beforeEach(() => {
    mockState = createState();
  });

  describe('SET_INITIAL_STATE', () => {
    it('should set the initial state', () => {
      const config = {
        resourceId: '1',
        pageType: 'groups',
        userCanDelete: '',
        emptyListIllustration: 'foo',
        emptyListHelpUrl: 'baz',
      };

      const expectedState = {
        ...mockState,
        config: {
          ...config,
          isGroupPage: true,
          canDestroyPackage: true,
        },
      };
      mutations[types.SET_INITIAL_STATE](mockState, config);

      expect(mockState.projectId).toEqual(expectedState.projectId);
    });
  });

  describe('SET_PACKAGE_LIST_SUCCESS', () => {
    it('should set a packages list', () => {
      const payload = [npmPackage, mavenPackage];
      const expectedState = { ...mockState, packages: payload };
      mutations[types.SET_PACKAGE_LIST_SUCCESS](mockState, payload);

      expect(mockState.packages).toEqual(expectedState.packages);
    });
  });

  describe('SET_MAIN_LOADING', () => {
    it('should set main loading', () => {
      mutations[types.SET_MAIN_LOADING](mockState, true);

      expect(mockState.isLoading).toEqual(true);
    });
  });

  describe('SET_PAGINATION', () => {
    const mockPagination = { perPage: 10, page: 1 };
    beforeEach(() => {
      commonUtils.normalizeHeaders = jest.fn().mockReturnValue('baz');
      commonUtils.parseIntPagination = jest.fn().mockReturnValue(mockPagination);
    });
    it('should set a parsed pagination', () => {
      mutations[types.SET_PAGINATION](mockState, 'foo');
      expect(commonUtils.normalizeHeaders).toHaveBeenCalledWith('foo');
      expect(commonUtils.parseIntPagination).toHaveBeenCalledWith('baz');
      expect(mockState.pagination).toEqual(mockPagination);
    });
  });
});
