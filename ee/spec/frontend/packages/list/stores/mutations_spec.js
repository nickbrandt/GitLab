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

  describe('SET_PROJECT_ID', () => {
    it('should set the project id', () => {
      const expectedState = { ...mockState, projectId: 'foo' };
      mutations[types.SET_PROJECT_ID](mockState, 'foo');

      expect(mockState.projectId).toEqual(expectedState.projectId);
    });
  });

  describe('SET_USER_CAN_DELETE', () => {
    it('should set the userCanDelete', () => {
      const expectedState = { ...mockState, userCanDelete: true };
      mutations[types.SET_USER_CAN_DELETE](mockState, true);

      expect(mockState.userCanDelete).toEqual(expectedState.userCanDelete);
    });
  });

  describe('SET_PACKAGE_LIST', () => {
    it('should set a packages list', () => {
      const payload = [npmPackage, mavenPackage];
      const expectedState = { ...mockState, packages: payload };
      mutations[types.SET_PACKAGE_LIST](mockState, payload);

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
      mutations[types.SET_PAGINATION](mockState, { headers: 'foo' });
      expect(commonUtils.normalizeHeaders).toHaveBeenCalledWith('foo');
      expect(commonUtils.parseIntPagination).toHaveBeenCalledWith('baz');
      expect(mockState.pagination).toEqual(mockPagination);
    });
  });
});
