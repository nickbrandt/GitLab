import { shallowMount } from '@vue/test-utils';
import { GlDeprecatedButton, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import AdminLicenseManagementRow from 'ee/vue_shared/license_compliance/components/admin_license_management_row.vue';
import LicenseManagementRow from 'ee/vue_shared/license_compliance/components/license_management_row.vue';
import AddLicenseForm from 'ee/vue_shared/license_compliance/components/add_license_form.vue';
import DeleteConfirmationModal from 'ee/vue_shared/license_compliance/components/delete_confirmation_modal.vue';
import { approvedLicense, blacklistedLicense } from './mock_data';

Vue.use(Vuex);

let wrapper;

const managedLicenses = [approvedLicense, blacklistedLicense];

const PaginatedListMock = {
  name: 'PaginatedList',
  props: ['list'],
  template: `
    <div>
      <slot name="header"></slot>
      <slot name="subheader"></slot>
      <slot :listItem="list[0]"></slot>
    </div>
  `,
};

const noop = () => {};

const createComponent = ({ state, getters, props, actionMocks, isAdmin }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        getters: {
          isAddingNewLicense: () => false,
          hasPendingLicenses: () => false,
          isLicenseBeingUpdated: () => () => false,
          ...getters,
        },
        state: {
          managedLicenses,
          isLoadingManagedLicenses: true,
          isAdmin,
          ...state,
        },
        actions: {
          fetchManagedLicenses: noop,
          setLicenseApproval: noop,
          ...actionMocks,
        },
      },
    },
  });

  wrapper = shallowMount(LicenseManagement, {
    propsData: {
      ...props,
    },
    stubs: {
      PaginatedList: PaginatedListMock,
    },
    store: fakeStore,
  });
};

describe('License Management', () => {
  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('common functionality', () => {
    describe.each`
      desc                | isAdmin
      ${'when admin'}     | ${true}
      ${'when developer'} | ${false}
    `('$desc', ({ isAdmin }) => {
      it('should render loading icon during initial loading', () => {
        createComponent({ state: { isLoadingManagedLicenses: true }, isAdmin });
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });

      it('should render list of managed licenses while updating a license', () => {
        createComponent({
          state: { isLoadingManagedLicenses: true },
          getters: { hasPendingLicenses: () => true },
          isAdmin,
        });
        expect(wrapper.find({ name: 'PaginatedList' }).props('list')).toBe(managedLicenses);
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false }, isAdmin });
        });

        it('should render list of managed licenses', () => {
          expect(wrapper.find({ name: 'PaginatedList' }).props('list')).toBe(managedLicenses);
        });
      });

      it('should mount and fetch licenses', () => {
        const fetchManagedLicensesMock = jest.fn();

        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: {
            fetchManagedLicenses: fetchManagedLicensesMock,
          },
          isAdmin,
        });

        expect(fetchManagedLicensesMock).toHaveBeenCalledWith(
          expect.any(Object),
          undefined,
          undefined,
        );
      });
    });
  });

  describe('permission based functionality', () => {
    describe('when admin', () => {
      it('should invoke `setLicenseAprroval` action on `addLicense` event on form only', () => {
        const setLicenseApprovalMock = jest.fn();
        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: { setLicenseApproval: setLicenseApprovalMock },
          isAdmin: true,
        });
        wrapper.find(GlDeprecatedButton).vm.$emit('click');

        return wrapper.vm.$nextTick().then(() => {
          wrapper.find(AddLicenseForm).vm.$emit('addLicense');
          expect(setLicenseApprovalMock).toHaveBeenCalled();
        });
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false }, isAdmin: true });
        });

        it('should render the form if the form is open and disable the form button', () => {
          wrapper.find(GlDeprecatedButton).vm.$emit('click');

          return wrapper.vm.$nextTick().then(() => {
            expect(wrapper.find(AddLicenseForm).exists()).toBe(true);
            expect(wrapper.find(GlDeprecatedButton).attributes('disabled')).toBe('true');
          });
        });

        it('should not render the form if the form is closed and have active button', () => {
          expect(wrapper.find(AddLicenseForm).exists()).toBe(false);
          expect(wrapper.find(GlDeprecatedButton).attributes('disabled')).not.toBe('true');
        });

        it('should render delete confirmation modal', () => {
          expect(wrapper.find(DeleteConfirmationModal).exists()).toBe(true);
        });

        it('renders the admin row', () => {
          expect(wrapper.find(LicenseManagementRow).exists()).toBe(false);
          expect(wrapper.find(AdminLicenseManagementRow).exists()).toBe(true);
        });
      });
    });
    describe('when developer', () => {
      it('should not invoke `setLicenseAprroval` action or `addLicense` event on form', () => {
        const setLicenseApprovalMock = jest.fn();
        createComponent({
          state: { isLoadingManagedLicenses: false },
          actionMocks: { setLicenseApproval: setLicenseApprovalMock },
          isAdmin: false,
        });
        expect(wrapper.find(GlDeprecatedButton).exists()).toBe(false);
        expect(wrapper.find(AddLicenseForm).exists()).toBe(false);
        expect(setLicenseApprovalMock).not.toHaveBeenCalled();
      });

      describe('when not loading', () => {
        beforeEach(() => {
          createComponent({ state: { isLoadingManagedLicenses: false, isAdmin: false } });
        });

        it('should not render the form', () => {
          expect(wrapper.find(AddLicenseForm).exists()).toBe(false);
          expect(wrapper.find(GlDeprecatedButton).exists()).toBe(false);
        });

        it('should not render delete confirmation modal', () => {
          expect(wrapper.find(DeleteConfirmationModal).exists()).toBe(false);
        });

        it('renders the read only row', () => {
          expect(wrapper.find(LicenseManagementRow).exists()).toBe(true);
          expect(wrapper.find(AdminLicenseManagementRow).exists()).toBe(false);
        });
      });
    });
  });
});
