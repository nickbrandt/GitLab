import Vuex from 'vuex';
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import ReleasesSort from '~/releases/components/releases_sort.vue';
import createStore from '~/releases/stores';
import createListModule from '~/releases/stores/modules/list';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_sort.vue', () => {
  let wrapper;
  let store;
  let sorting;
  let listModule;
  let sortingItems;
  const projectId = 8;

  const createComponent = () => {
    listModule = createListModule({ projectId });

    store = createStore({
      modules: {
        list: listModule,
      },
    });

    store.dispatch = jest.fn();

    wrapper = mount(ReleasesSort, {
      store,
      stubs: {
        ...stubChildren(ReleasesSort),
        GlSortingItem,
      },
      localVue,
    });
  };

  const findReleasesSorting = () => wrapper.find(GlSorting);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
    sorting = findReleasesSorting();
    sortingItems = findSortingItems();
  });

  it('has all the sortable items', () => {
    expect(sortingItems).toHaveLength(wrapper.vm.sortOptions.length);
  });

  it('on sort change set sorting in vuex and emit event', () => {
    sorting.vm.$emit('sortDirectionChange');
    expect(store.dispatch).toHaveBeenCalledWith('list/setSorting', { sort: 'asc' });
    expect(wrapper.emitted('sort:changed')).toBeTruthy();
  });

  it('on sort item click set sorting and emit event', () => {
    const item = sortingItems.at(0);
    const { orderBy } = wrapper.vm.sortOptions[0];
    item.vm.$emit('click');
    expect(store.dispatch).toHaveBeenCalledWith('list/setSorting', { orderBy });
    expect(wrapper.emitted('sort:changed')).toBeTruthy();
  });
});
