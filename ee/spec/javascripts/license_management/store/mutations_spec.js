import createStore from 'ee/vue_shared/license_management/store';
import * as types from 'ee/vue_shared/license_management/store/mutation_types';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

import { TEST_HOST } from 'spec/test_constants';
import { approvedLicense } from 'ee_spec/license_management/mock_data';

describe('License store mutations', () => {
  let store;

  beforeEach(() => {
    store = createStore();
  });

  describe('SET_LICENSE_IN_MODAL', () => {
    it('opens modal and sets passed license', () => {
      store.commit(types.SET_LICENSE_IN_MODAL, approvedLicense);

      expect(store.state.currentLicenseInModal).toBe(approvedLicense);
    });
  });

  describe('RESET_LICENSE_IN_MODAL', () => {
    it('closes modal and deletes licenseInApproval', () => {
      store.replaceState({
        ...store.state,
        currentLicenseInModal: approvedLicense,
      });

      store.commit(types.RESET_LICENSE_IN_MODAL);

      expect(store.state.currentLicenseInModal).toBeNull();
    });
  });

  describe('SET_API_SETTINGS', () => {
    it('assigns data to the store', () => {
      const data = { apiUrlManageLicenses: TEST_HOST };

      store.commit(types.SET_API_SETTINGS, data);

      expect(store.state.apiUrlManageLicenses).toBe(TEST_HOST);
    });
  });

  describe('RECEIVE_DELETE_LICENSE', () => {
    it('sets isDeleting to false and closes the modal', () => {
      store.replaceState({
        ...store.state,
        isDeleting: true,
      });

      store.commit(types.RECEIVE_DELETE_LICENSE);

      expect(store.state.isDeleting).toBe(false);
    });
  });

  describe('RECEIVE_DELETE_LICENSE_ERROR', () => {
    it('sets isDeleting to false and closes the modal', () => {
      store.replaceState({
        ...store.state,
        isDeleting: true,
        currentLicenseInModal: approvedLicense,
      });

      store.commit(types.RECEIVE_DELETE_LICENSE_ERROR);

      expect(store.state.isDeleting).toBe(false);
      expect(store.state.currentLicenseInModal).toBeNull();
    });
  });

  describe('REQUEST_DELETE_LICENSE', () => {
    it('sets isDeleting to true', () => {
      store.replaceState({
        ...store.state,
        isDeleting: false,
      });

      store.commit(types.REQUEST_DELETE_LICENSE);

      expect(store.state.isDeleting).toBe(true);
    });
  });

  describe('RECEIVE_SET_LICENSE_APPROVAL', () => {
    it('sets isSaving to false and closes the modal', () => {
      store.replaceState({
        ...store.state,
        isSaving: true,
      });

      store.commit(types.RECEIVE_SET_LICENSE_APPROVAL);

      expect(store.state.isSaving).toBe(false);
    });
  });

  describe('RECEIVE_SET_LICENSE_APPROVAL_ERROR', () => {
    it('sets isSaving to false and closes the modal', () => {
      store.replaceState({
        ...store.state,
        isSaving: true,
        currentLicenseInModal: approvedLicense,
      });

      store.commit(types.RECEIVE_SET_LICENSE_APPROVAL_ERROR);

      expect(store.state.isSaving).toBe(false);
      expect(store.state.currentLicenseInModal).toBeNull();
    });
  });

  describe('REQUEST_SET_LICENSE_APPROVAL', () => {
    it('sets isSaving to true', () => {
      store.replaceState({
        ...store.state,
        isSaving: false,
      });

      store.commit(types.REQUEST_SET_LICENSE_APPROVAL);

      expect(store.state.isSaving).toBe(true);
    });
  });

  describe('RECEIVE_MANAGED_LICENSES_SUCCESS', () => {
    it('sets isLoadingManagedLicenses and loadManagedLicensesError to false and saves managed licenses', () => {
      store.replaceState({
        ...store.state,
        managedLicenses: false,
        isLoadingManagedLicenses: true,
        loadManagedLicensesError: true,
      });

      store.commit(types.RECEIVE_MANAGED_LICENSES_SUCCESS, [
        { name: 'Foo', approval_status: LICENSE_APPROVAL_STATUS.approved },
      ]);

      expect(store.state.managedLicenses).toEqual([
        { name: 'Foo', approvalStatus: LICENSE_APPROVAL_STATUS.approved },
      ]);

      expect(store.state.isLoadingManagedLicenses).toBe(false);
      expect(store.state.loadManagedLicensesError).toBe(false);
    });
  });

  describe('RECEIVE_MANAGED_LICENSES_ERROR', () => {
    it('sets isLoadingManagedLicenses to true and saves the error', () => {
      const error = new Error('test');
      store.replaceState({
        ...store.state,
        isLoadingManagedLicenses: true,
        loadManagedLicensesError: false,
      });

      store.commit(types.RECEIVE_MANAGED_LICENSES_ERROR, error);

      expect(store.state.isLoadingManagedLicenses).toBe(false);
      expect(store.state.loadManagedLicensesError).toBe(error);
    });
  });

  describe('REQUEST_MANAGED_LICENSES', () => {
    it('sets isLoadingManagedLicenses to true', () => {
      store.replaceState({
        ...store.state,
        isLoadingManagedLicenses: true,
      });

      store.commit(types.REQUEST_MANAGED_LICENSES);

      expect(store.state.isLoadingManagedLicenses).toBe(true);
    });
  });

  describe('RECEIVE_PARSED_LICENSE_REPORT_SUCCESS', () => {
    const newLicenses = [];
    const existingLicenses = [];

    beforeEach(() => {
      store.state.isLoadingLicenseReport = true;
      store.state.loadLicenseReportError = new Error('test');
      store.commit(types.RECEIVE_PARSED_LICENSE_REPORT_SUCCESS, { newLicenses, existingLicenses });
    });

    it('should set the new and existing reports', () => {
      expect(store.state.newLicenses).toBe(newLicenses);
      expect(store.state.existingLicenses).toBe(existingLicenses);
    });

    it('should cancel loading and clear any errors', () => {
      expect(store.state.isLoadingLicenseReport).toBe(false);
      expect(store.state.loadLicenseReportError).toBe(false);
    });
  });

  describe('RECEIVE_PARSED_LICENSE_REPORT_ERROR', () => {
    const error = new Error('test');
    beforeEach(() => {
      store.state.isLoadingLicenseReport = true;
      store.state.loadLicenseReportError = false;
      store.commit(types.RECEIVE_PARSED_LICENSE_REPORT_ERROR, error);
    });

    it('should set the error on the state', () => {
      expect(store.state.loadLicenseReportError).toBe(error);
    });

    it('should cancel loading', () => {
      expect(store.state.isLoadingLicenseReport).toBe(false);
    });
  });

  describe('REQUEST_PARSED_LICENSE_REPORT', () => {
    beforeEach(() => {
      store.state.isLoadingLicenseReport = false;
      store.commit(types.REQUEST_PARSED_LICENSE_REPORT);
    });

    it('should initiate loading', () => {
      expect(store.state.isLoadingLicenseReport).toBe(true);
    });
  });
});
