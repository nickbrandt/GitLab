import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import DesignVersionDropdown from 'ee/design_management/components/upload/design_version_dropdown.vue';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import mockAllVersions from './mock_data/all_versions';

const VERSION_ID = 3;
const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

describe('Design management design version dropdown component', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(DesignVersionDropdown, {
      propsData: {
        projectPath: '',
        issueIid: '',
      },
      localVue,
      router,
    });

    wrapper.setData({
      allVersions: mockAllVersions,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findVersionLink = index => wrapper.findAll('.js-version-link').at(index);

  it('renders design version dropdown button', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders design version list', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('selected version name', () => {
    it('has "latest" on most recent version item', () => {
      createComponent();

      expect(findVersionLink(0).text()).toContain('latest');
    });
  });

  describe('versions list', () => {
    it('pushes version id when a version is clicked', () => {
      createComponent();
      wrapper.vm.$router.push(`/designs?version=${VERSION_ID}`);
      const CurrentVersionNumber = wrapper.vm.getCurrentVersionNumber();

      expect(wrapper.find(GlDropdown).attributes('text')).toBe(
        `Showing Version #${CurrentVersionNumber}`,
      );
    });

    it('should have the same length as apollo query', () => {
      createComponent();

      expect(wrapper.findAll(GlDropdownItem).length).toEqual(wrapper.vm.allVersions.length);
    });
  });
});
