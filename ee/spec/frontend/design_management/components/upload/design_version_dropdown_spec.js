import { createLocalVue, shallowMount } from '@vue/test-utils';
import DesignVersionDropdown from 'ee/design_management/components/upload/design_version_dropdown.vue';
import { GlDropdown, GlDropdownItem, GlAvatar } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import mockAllVersions from './mock_data/all_versions';

const LATEST_VERSION_ID = 3;
const PREVIOUS_VERSION_ID = 2;

const localVue = createLocalVue();

const designRouteFactory = versionId => ({
  path: `/designs?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/designs',
  query: {},
};

describe('Design management design version dropdown component', () => {
  let wrapper;

  function createComponent({ maxVersions = -1, $route = MOCK_ROUTE } = {}) {
    wrapper = shallowMount(DesignVersionDropdown, {
      propsData: {
        projectPath: '',
        issueIid: '',
      },
      localVue,
      mocks: {
        $route,
      },
      stubs: ['router-link'],
    });

    wrapper.setData({
      allVersions: maxVersions > -1 ? mockAllVersions.slice(0, maxVersions) : mockAllVersions,
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
    it('displays latest version text by default', () => {
      createComponent();

      expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing Latest Version');
    });

    it('displays latest version text when only 1 version is present', () => {
      createComponent({ maxVersions: 1 });

      expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing Latest Version');
    });

    it('displays version text when the current version is not the latest', () => {
      createComponent({ $route: designRouteFactory(PREVIOUS_VERSION_ID) });
      expect(wrapper.find(GlDropdown).attributes('text')).toBe(`Showing Version #1`);
    });

    it('displays latest version text when the current version is the latest', () => {
      createComponent({ $route: designRouteFactory(LATEST_VERSION_ID) });
      expect(wrapper.find(GlDropdown).attributes('text')).toBe('Showing Latest Version');
    });

    it("displays the user's avatar", () => {
      createComponent();

      expect(wrapper.find(GlAvatar).props('src')).toEqual(mockAllVersions[0].node.author.avatarUrl);
    });

    it('displays the created at tooltip', () => {
      createComponent();

      expect(wrapper.find(TimeAgoTooltip).props('time')).toEqual(mockAllVersions[0].node.createdAt);
    });

    it('should have the same length as apollo query', () => {
      createComponent();

      expect(wrapper.findAll(GlDropdownItem).length).toEqual(wrapper.vm.allVersions.length);
    });
  });
});
