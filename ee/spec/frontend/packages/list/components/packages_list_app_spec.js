import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState, GlTab, GlTabs } from '@gitlab/ui';
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
  const findTabComponent = (index = 0) => wrapper.findAll(GlTab).at(index);

  const mountComponent = () => {
    wrapper = shallowMount(PackageListApp, {
      localVue,
      store,
      stubs: {
        GlEmptyState,
        GlLoadingIcon,
        PackageList,
        GlTab,
        GlTabs,
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
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('empty state', () => {
    it('generate the correct empty list link', () => {
      const link = findListComponent().find('a');

      expect(link.html()).toMatchInlineSnapshot(
        `"<a href=\\"${emptyListHelpUrl}\\" target=\\"_blank\\">publish and share your packages</a>"`,
      );
    });

    it('includes the right content on the default tab', () => {
      const heading = findListComponent().find('h4');

      expect(heading.text()).toBe('There are no packages yet');
    });
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

  describe('tab change', () => {
    it('calls requestPackagesList when all tab is clicked', () => {
      findTabComponent().trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
    });

    it('calls requestPackagesList when a package type tab is clicked', () => {
      findTabComponent(1).trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('requestPackagesList');
    });
  });
});
