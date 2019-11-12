import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlTable } from '@gitlab/ui';
import PackagesList from 'ee/packages/list/components/packages_list.vue';
import { packageList } from '../../mock_data';

describe('packages_list', () => {
  let wrapper;

  const findFirstActionColumn = (w = wrapper) => w.find({ ref: 'action-delete' });
  const findPackageListTable = (w = wrapper) => w.find({ ref: 'packageListTable' });
  const findPackageListSorting = (w = wrapper) => w.find({ ref: 'packageListSorting' });
  const findPackageListPagination = (w = wrapper) => w.find({ ref: 'packageListPagination' });
  const findPackageListDeleteModal = (w = wrapper) => w.find({ ref: 'packageListDeleteModal' });
  const findSortingItems = (w = wrapper) => w.findAll({ name: 'sorting-item-stub' });

  const defaultShallowMountOptions = {
    propsData: {
      canDestroyPackage: true,
    },
    stubs: {
      GlTable,
      GlSortingItem: { name: 'sorting-item-stub', template: '<div><slot></slot></div>' },
    },
    computed: {
      list: () => [...packageList],
    },
  };

  beforeEach(() => {
    // This is needed due to  console.error called by vue to emit a warning that stop the tests
    // see  https://github.com/vuejs/vue-test-utils/issues/532
    Vue.config.silent = true;
    wrapper = shallowMount(PackagesList, defaultShallowMountOptions);
  });

  afterEach(() => {
    Vue.config.silent = false;
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('contains a sorting component', () => {
    const sorting = findPackageListSorting();
    expect(sorting.exists()).toBe(true);
  });

  it('contains a table component', () => {
    const sorting = findPackageListTable();
    expect(sorting.exists()).toBe(true);
  });

  it('contains a pagination component', () => {
    const sorting = findPackageListPagination();
    expect(sorting.exists()).toBe(true);
  });
  it('contains a modal component', () => {
    const sorting = findPackageListDeleteModal();
    expect(sorting.exists()).toBe(true);
  });

  describe('when user can not destroy the package', () => {
    it('does not show the action column', () => {
      wrapper.setProps({ canDestroyPackage: false });
      const action = findFirstActionColumn();
      expect(action.exists()).toBe(false);
    });
  });

  describe('when the user can destroy the package', () => {
    it('show the action column', () => {
      const action = findFirstActionColumn();
      expect(action.exists()).toBe(true);
    });

    it('shows the correct deletePackageDescription', () => {
      expect(wrapper.vm.deletePackageDescription).toEqual('');

      wrapper.setData({ itemToBeDeleted: { name: 'foo' } });
      expect(wrapper.vm.deletePackageDescription).toEqual(
        'You are about to delete <b>foo</b>, this operation is irreversible, are you sure?',
      );
    });

    it('delete button set itemToBeDeleted and open the modal', () => {
      wrapper.vm.$refs.packageListDeleteModal.show = jest.fn();
      const [{ name, id }] = packageList.slice(-1);
      const action = findFirstActionColumn();
      action.vm.$emit('click');
      return Vue.nextTick().then(() => {
        expect(wrapper.vm.itemToBeDeleted).toEqual({ id, name });
        expect(wrapper.vm.$refs.packageListDeleteModal.show).toHaveBeenCalled();
      });
    });

    it('deleteItemConfirmation resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemConfirmation();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
    });

    it('deleteItemCanceled resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemCanceled();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
    });
  });

  describe('when the list is empty', () => {
    const findEmptySlot = (w = wrapper) => w.find({ name: 'empty-slot-stub' });

    beforeEach(() => {
      wrapper = shallowMount(PackagesList, {
        ...defaultShallowMountOptions,
        computed: { list: () => [] },
        slots: {
          'empty-state': { name: 'empty-slot-stub', template: '<div>bar</div>' },
        },
      });
    });

    it('show the empty slot', () => {
      const table = findPackageListTable();
      const emptySlot = findEmptySlot();
      expect(table.exists()).toBe(false);
      expect(emptySlot.exists()).toBe(true);
    });
  });

  describe('sorting component', () => {
    it('has all the sortable items', () => {
      const sortingItems = findSortingItems();
      expect(sortingItems.length).toEqual(wrapper.vm.sortableFields.length);
    });
  });
});
