import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import PackageListApp from 'ee/packages/list/components/packages_list_app.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_list_app', () => {
  let wrapper;
  let store;

  const PackageList = {
    name: 'package-list',
    template: '<div><slot name="empty-state"></slot></div>',
  };
  const GlLoadingIcon = { name: 'gl-loading-icon', template: '<div>loading</div>' };

  const emptyListHelpUrl = 'helpUrl';
  const findListComponent = () => wrapper.find(PackageList);
  const findLoadingComponent = () => wrapper.find(GlLoadingIcon);

  const mountComponent = () => {
    wrapper = shallowMount(PackageListApp, {
      localVue,
      store,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        config: {
          resourceId: 'project_id',
          emptyListIllustration: 'helpSvg',
          emptyListHelpUrl: 'helpUrl',
        },
      },
    });
    store.dispatch = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when isLoading is true', () => {
    beforeEach(() => {
      store.state.isLoading = true;
      mountComponent();
    });

    it('shows the loading component', () => {
      const loader = findLoadingComponent();
      expect(loader.exists()).toBe(true);
    });
  });

  describe('when isLoading is false', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('generate the correct empty list link', () => {
      const emptyState = findListComponent();
      const link = emptyState.find('a');

      expect(link.html()).toMatchInlineSnapshot(
        `"<a href=\\"${emptyListHelpUrl}\\" target=\\"_blank\\">publish and share your packages</a>"`,
      );
    });

    it('call requestPackagesList on page:changed', () => {
      const list = findListComponent();
      list.vm.$emit('page:changed', 1);
      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList', { page: 1 });
    });

    it('call requestDeletePackage on package:delete', () => {
      const list = findListComponent();
      list.vm.$emit('package:delete', 'foo');
      expect(store.dispatch).toHaveBeenCalledWith('requestDeletePackage', 'foo');
    });

    it('calls requestPackagesList on sort:changed', () => {
      const list = findListComponent();
      list.vm.$emit('sort:changed');
      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
    });
  });
});
