import Vuex from 'vuex';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import PackagesListRow from 'ee/packages/list/components/packages_list_row.vue';
import PackageTags from 'ee/packages/shared/components/package_tags.vue';
import { packageList } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_list_row', () => {
  let wrapper;
  let store;

  const [packageWithoutTags, packageWithTags] = packageList;

  const findPackageTags = () => wrapper.find(PackageTags);
  const findProjectLink = () => wrapper.find({ ref: 'packages-row-project' });
  const findDeleteButton = () => wrapper.find({ ref: 'action-delete' });

  const mountComponent = (
    isGroupPage = false,
    packageEntity = packageWithoutTags,
    shallow = true,
  ) => {
    const mountFunc = shallow ? shallowMount : mount;

    const state = {
      config: {
        isGroupPage,
      },
    };

    store = new Vuex.Store({
      state,
      getters: {
        getCommitLink: () => () => {
          return 'commit-link';
        },
      },
    });

    wrapper = mountFunc(PackagesListRow, {
      localVue,
      store,
      propsData: {
        packageEntity,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('tags', () => {
    it('renders package tags when a package has tags', () => {
      mountComponent(false, packageWithTags);

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not render when there are no tags', () => {
      mountComponent();

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('when is isGroupPage', () => {
    beforeEach(() => {
      mountComponent(true);
    });

    it('has project field', () => {
      expect(findProjectLink().exists()).toBe(true);
    });

    it('does not show the delete button', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('delete event', () => {
    beforeEach(() => mountComponent(false, packageWithoutTags, false));

    it('emits the packageToDelete event when the delete button is clicked', () => {
      findDeleteButton().trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('packageToDelete')).toBeTruthy();
        expect(wrapper.emitted('packageToDelete')[0]).toEqual([packageWithoutTags]);
      });
    });
  });
});
