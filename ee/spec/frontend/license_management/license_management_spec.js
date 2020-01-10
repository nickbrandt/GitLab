import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import Vuex from 'vuex';
import LicenseManagement from 'ee/vue_shared/license_management/license_management.vue';
import AddLicenseForm from 'ee/vue_shared/license_management/components/add_license_form.vue';
import DeleteConfirmationModal from 'ee/vue_shared/license_management/components/delete_confirmation_modal.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { approvedLicense, blacklistedLicense } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

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

describe('LicenseManagement', () => {
  const apiUrl = `${TEST_HOST}/license_management`;
  const managedLicenses = [approvedLicense, blacklistedLicense];
  let wrapper;

  const createComponent = ({ state, props, actionMocks }) => {
    const fakeStore = new Vuex.Store({
      state: {
        managedLicenses,
        isLoadingManagedLicenses: true,
        ...state,
      },
      actions: {
        loadManagedLicenses: noop,
        setAPISettings: noop,
        setLicenseApproval: noop,
        ...actionMocks,
      },
    });

    wrapper = shallowMount(LicenseManagement, {
      propsData: {
        apiUrl,
        ...props,
      },
      stubs: {
        LicenseManagementRow: true,
        PaginatedList: PaginatedListMock,
      },
      store: fakeStore,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('when loading should render loading icon', () => {
    createComponent({ state: { isLoadingManagedLicenses: true } });
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when not loading', () => {
    beforeEach(() => {
      createComponent({ state: { isLoadingManagedLicenses: false } });
    });

    it('should render the form if the form is open and disable the form button', () => {
      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(AddLicenseForm).exists()).toBe(true);
        expect(wrapper.find(GlButton).attributes('disabled')).toBe('true');
      });
    });

    it('should not render the form if the form is closed and have active button', () => {
      expect(wrapper.find(AddLicenseForm).exists()).toBe(false);
      expect(wrapper.find(GlButton).attributes('disabled')).not.toBe('true');
    });

    it('should render delete confirmation modal', () => {
      expect(wrapper.find(DeleteConfirmationModal).exists()).toBe(true);
    });

    it('should render list of managed licenses', () => {
      expect(wrapper.find({ name: 'PaginatedList' }).props('list')).toBe(managedLicenses);
    });
  });

  it('should invoke `setLicenseAprroval` action on `addLicense` event on form', () => {
    const setLicenseApprovalMock = jest.fn();
    createComponent({
      state: { isLoadingManagedLicenses: false },
      actionMocks: { setLicenseApproval: setLicenseApprovalMock },
    });
    wrapper.find(GlButton).vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      wrapper.find(AddLicenseForm).vm.$emit('addLicense');
      expect(setLicenseApprovalMock).toHaveBeenCalled();
    });
  });

  it('should set api settings after mount and init API calls', () => {
    const setAPISettingsMock = jest.fn();
    const loadManagedLicensesMock = jest.fn();

    createComponent({
      state: { isLoadingManagedLicenses: false },
      actionMocks: {
        setAPISettings: setAPISettingsMock,
        loadManagedLicenses: loadManagedLicensesMock,
      },
    });

    expect(setAPISettingsMock).toHaveBeenCalledWith(
      expect.any(Object),
      {
        apiUrlManageLicenses: apiUrl,
      },
      undefined,
    );

    expect(loadManagedLicensesMock).toHaveBeenCalledWith(expect.any(Object), undefined, undefined);
  });
});
