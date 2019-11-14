import * as actions from 'ee/packages/list/stores/actions';
import * as types from 'ee/packages/list/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import Api from '~/api';

jest.mock('~/flash.js');
jest.mock('~/api.js');

describe('Actions Package list store', () => {
  let state;

  beforeEach(() => {
    state = {
      pagination: {
        page: 1,
        perPage: 10,
      },
    };
  });

  describe('requestPackagesList', () => {
    beforeEach(() => {
      Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo' });
    });

    it('should dispatch the correct actions', done => {
      testAction(
        actions.requestPackagesList,
        null,
        state,
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: 'foo' },
          { type: 'setLoading', payload: false },
        ],
        done,
      );
    });

    it('should create flash on API error', done => {
      Api.projectPackages = jest.fn().mockRejectedValue();
      testAction(
        actions.requestPackagesList,
        null,
        state,
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
      testAction(
        actions.receivePackagesListSuccess,
        'foo',
        state,
        [{ type: types.SET_PACKAGE_LIST_SUCCESS, payload: 'foo' }],
        [],
        done,
      );
    });
  });

  describe('setProjectId', () => {
    it('should commit setProjectId', done => {
      testAction(
        actions.setProjectId,
        '1',
        state,
        [{ type: types.SET_PROJECT_ID, payload: '1' }],
        [],
        done,
      );
    });
  });

  describe('setUserCanDelete', () => {
    it('should commit setUserCanDelete', done => {
      testAction(
        actions.setUserCanDelete,
        true,
        state,
        [{ type: types.SET_USER_CAN_DELETE, payload: true }],
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
        state,
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
          { type: 'fetchPackages' },
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
