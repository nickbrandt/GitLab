import Vuex from 'vuex';
import { last } from 'lodash';
import { GlTable, GlSorting, GlPagination, GlModal } from '@gitlab/ui';
import Tracking from '~/tracking';
import { mount, createLocalVue } from '@vue/test-utils';
import PackagesList from 'ee/packages/list/components/packages_list.vue';
import PackageTags from 'ee/packages/shared/components/package_tags.vue';
import * as SharedUtils from 'ee/packages/shared/utils';
import { TrackingActions } from 'ee/packages/shared/constants';
import stubChildren from 'helpers/stub_children';
import { packageList } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_list', () => {
  let wrapper;
  let store;
  let state;
  let getListSpy;

  const GlSortingItem = { name: 'sorting-item-stub', template: '<div><slot></slot></div>' };
  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>bar</div>' };

  const findFirstActionColumn = () => wrapper.find({ ref: 'action-delete' });
  const findPackageListTable = () => wrapper.find(GlTable);
  const findPackageListSorting = () => wrapper.find(GlSorting);
  const findPackageListPagination = () => wrapper.find(GlPagination);
  const findPackageListDeleteModal = () => wrapper.find(GlModal);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);
  const findFirstProjectColumn = () => wrapper.find({ ref: 'col-project' });
  const findPackageTags = () => wrapper.findAll(PackageTags);
  const findEmptySlot = () => wrapper.find({ name: 'empty-slot-stub' });

  const mountComponent = options => {
    wrapper = mount(PackagesList, {
      localVue,
      store,
      stubs: {
        ...stubChildren(PackagesList),
        GlTable,
        GlSortingItem,
      },
      ...options,
    });
  };

  beforeEach(() => {
    getListSpy = jest.fn();
    getListSpy.mockReturnValue(packageList);
    state = {
      packages: [...packageList],
      pagination: {
        perPage: 1,
        total: 1,
        page: 1,
      },
      config: {
        isGroupPage: false,
      },
      sorting: {
        orderBy: 'version',
        sort: 'desc',
      },
    };
    store = new Vuex.Store({
      state,
      getters: {
        getList: getListSpy,
      },
    });
    store.dispatch = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when is isGroupPage', () => {
    beforeEach(() => {
      state.config.isGroupPage = true;
      mountComponent();
    });

    it('has project field', () => {
      const projectColumn = findFirstProjectColumn();
      expect(projectColumn.exists()).toBe(true);
    });

    it('does not show the action column', () => {
      const action = findFirstActionColumn();
      expect(action.exists()).toBe(false);
    });
  });

  describe('layout', () => {
    beforeEach(() => {
      mountComponent();
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

    it('renders package tags when a package has tags', () => {
      expect(findPackageTags()).toHaveLength(1);
    });
  });

  describe('when the user can destroy the package', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('show the action column', () => {
      const action = findFirstActionColumn();
      expect(action.exists()).toBe(true);
    });

    it('shows the correct deletePackageDescription', () => {
      expect(wrapper.vm.deletePackageDescription).toEqual('');

      wrapper.setData({ itemToBeDeleted: { name: 'foo', version: '1.0.10-beta' } });
      expect(wrapper.vm.deletePackageDescription).toMatchInlineSnapshot(
        `"You are about to delete <b>foo:1.0.10-beta</b>, this operation is irreversible, are you sure?"`,
      );
    });

    it('delete button set itemToBeDeleted and open the modal', () => {
      wrapper.vm.$refs.packageListDeleteModal.show = jest.fn();
      const item = last(wrapper.vm.list);
      const action = findFirstActionColumn();
      action.vm.$emit('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.itemToBeDeleted).toEqual(item);
        expect(wrapper.vm.$refs.packageListDeleteModal.show).toHaveBeenCalled();
      });
    });

    it('deleteItemConfirmation resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemConfirmation();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
    });

    it('deleteItemConfirmation emit package:delete', () => {
      const itemToBeDeleted = { id: 2 };
      wrapper.setData({ itemToBeDeleted });
      wrapper.vm.deleteItemConfirmation();
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.emitted('package:delete')[0]).toEqual([itemToBeDeleted]);
      });
    });

    it('deleteItemCanceled resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemCanceled();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
    });
  });

  describe('when the list is empty', () => {
    beforeEach(() => {
      getListSpy.mockReturnValue([]);
      mountComponent({
        slots: {
          'empty-state': EmptySlotStub,
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
    let sorting;
    let sortingItems;

    beforeEach(() => {
      mountComponent();
      sorting = findPackageListSorting();
      sortingItems = findSortingItems();
    });

    it('has all the sortable items', () => {
      expect(sortingItems.length).toEqual(wrapper.vm.sortableFields.length);
    });

    it('on sort change set sorting in vuex and emit event', () => {
      sorting.vm.$emit('sortDirectionChange');
      expect(store.dispatch).toHaveBeenCalledWith('setSorting', { sort: 'asc' });
      expect(wrapper.emitted('sort:changed')).toBeTruthy();
    });

    it('on sort item click set sorting and emit event', () => {
      const item = sortingItems.at(0);
      const { orderBy } = wrapper.vm.sortableFields[0];
      item.vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('setSorting', { orderBy });
      expect(wrapper.emitted('sort:changed')).toBeTruthy();
    });
  });

  describe('pagination component', () => {
    let pagination;
    let modelEvent;

    beforeEach(() => {
      mountComponent();
      pagination = findPackageListPagination();
      // retrieve the event used by v-model, a more sturdy approach than hardcoding it
      modelEvent = pagination.vm.$options.model.event;
    });

    it('emits page:changed events when the page changes', () => {
      pagination.vm.$emit(modelEvent, 2);
      expect(wrapper.emitted('page:changed')).toEqual([[2]]);
    });
  });

  describe('table component', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('has stacked-md class', () => {
      const table = findPackageListTable();
      expect(table.classes()).toContain('b-table-stacked-md');
    });
  });

  describe('tracking', () => {
    let eventSpy;
    let utilSpy;
    const category = 'foo';

    beforeEach(() => {
      mountComponent();
      eventSpy = jest.spyOn(Tracking, 'event');
      utilSpy = jest.spyOn(SharedUtils, 'packageTypeToTrackCategory').mockReturnValue(category);
      wrapper.setData({ itemToBeDeleted: { package_type: 'conan' } });
    });

    it('tracking category calls packageTypeToTrackCategory', () => {
      expect(wrapper.vm.tracking.category).toBe(category);
      expect(utilSpy).toHaveBeenCalledWith('conan');
    });

    it('deleteItemConfirmation calls event', () => {
      wrapper.vm.deleteItemConfirmation();
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        TrackingActions.DELETE_PACKAGE,
        expect.any(Object),
      );
    });
  });
});
