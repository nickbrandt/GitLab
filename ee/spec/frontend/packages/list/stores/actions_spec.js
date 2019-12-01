import * as actions from 'ee/packages/list/stores/actions';
import * as types from 'ee/packages/list/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import Api from 'ee/api';

jest.mock('~/flash.js');
jest.mock('ee/api.js');

describe('Actions Package list store', () => {
  const headers = 'bar';

  describe('requestPackagesList', () => {
    beforeEach(() => {
      Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo', headers });
      Api.groupPackages = jest.fn().mockResolvedValue({ data: 'baz', headers });
    });

    it('should fetch the project packages list when isGroupPage is false', done => {
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: false, resourceId: 1 } },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'foo', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.projectPackages).toHaveBeenCalledWith(1, {
            params: { page: 1, per_page: 20 },
          });
          done();
        },
      );
    });

    it('should fetch the group packages list when  isGroupPage is true', done => {
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: true, resourceId: 2 } },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'baz', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.groupPackages).toHaveBeenCalledWith(2, {
            params: { page: 1, per_page: 20 },
          });
          done();
        },
      );
    });

    it('should create flash on API error', done => {
      Api.projectPackages = jest.fn().mockRejectedValue();
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: false, resourceId: 2 } },
        [],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('receivePackagesListSuccess', () => {
    it('should set received packages', done => {
      const data = 'foo';

      testAction(
        actions.receivePackagesListSuccess,
        { data, headers },
        null,
        [
          { type: types.SET_PACKAGE_LIST_SUCCESS, payload: data },
          { type: types.SET_PAGINATION, payload: headers },
        ],
        [],
        done,
      );
    });
  });

  describe('setInitialState', () => {
    it('should commit setInitialState', done => {
      testAction(
        actions.setInitialState,
        '1',
        null,
        [{ type: types.SET_INITIAL_STATE, payload: '1' }],
        [],
        done,
      );
    });
  });

  describe('setLoading', () => {
    it('should commit set main loading', done => {
      testAction(
        actions.setLoading,
        true,
        null,
        [{ type: types.SET_MAIN_LOADING, payload: true }],
        [],
        done,
      );
    });
  });

  describe('requestDeletePackage', () => {
    it('should call deleteProjectPackage', done => {
      Api.deleteProjectPackage = jest.fn().mockResolvedValue({ data: 'foo' });
      Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo' });

      testAction(
        actions.requestDeletePackage,
        {
          projectId: 1,
          packageId: 2,
        },
        null,
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'requestPackagesList' },
          { type: 'setLoading', payload: false },
        ],
        done,
      );
    });

    it('should stop the loading and call create flash on api error', done => {
      Api.deleteProjectPackage = jest.fn().mockRejectedValue();
      testAction(
        actions.requestDeletePackage,
        {
          projectId: 1,
          packageId: 2,
        },
        null,
        [],
        [{ type: 'setLoading', payload: true }, { type: 'setLoading', payload: false }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });
});
