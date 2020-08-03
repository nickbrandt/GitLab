import { mount, shallowMount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import { merge } from 'lodash';
import DastProfiles from 'ee/dast_profiles/components/dast_profiles.vue';
import DastProfilesList from 'ee/dast_profiles/components/dast_profiles_list.vue';

const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';
const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('EE - DastProfiles', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      newDastSiteProfilePath: TEST_NEW_DAST_SITE_PROFILE_PATH,
      projectFullPath: TEST_PROJECT_FULL_PATH,
    };

    const defaultMocks = {
      $apollo: {
        queries: {
          siteProfiles: {},
        },
      },
    };

    wrapper = mountFn(
      DastProfiles,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: defaultMocks,
        },
        options,
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const getSiteProfilesComponent = () => wrapper.find(DastProfilesList);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('header', () => {
    beforeEach(() => {
      createFullComponent();
    });

    it('shows a heading that describes the purpose of the page', () => {
      const heading = withinComponent().getByRole('heading', { name: /manage profiles/i });

      expect(heading).not.toBe(null);
    });

    it(`shows a "New Site Profile" anchor that links to ${TEST_NEW_DAST_SITE_PROFILE_PATH}`, () => {
      const newProfileButton = withinComponent().getByRole('link', { name: /new site profile/i });

      expect(newProfileButton.getAttribute('href')).toBe(TEST_NEW_DAST_SITE_PROFILE_PATH);
    });
  });

  describe('tabs', () => {
    beforeEach(() => {
      createFullComponent();
    });

    it('shows a tab-list that contains the different profile categories', () => {
      const tabList = withinComponent().getByRole('tablist');

      expect(tabList).not.toBe(null);
    });

    it.each`
      tabName            | shouldBeSelectedByDefault
      ${'Site Profiles'} | ${true}
    `(
      'shows a "$tabName" tab which has "selected" set to "$shouldBeSelectedByDefault"',
      ({ tabName, shouldBeSelectedByDefault }) => {
        const tab = withinComponent().getByRole('tab', {
          name: tabName,
          selected: shouldBeSelectedByDefault,
        });

        expect(tab).not.toBe(null);
      },
    );
  });

  describe('site profiles', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes down the correct default props', () => {
      expect(getSiteProfilesComponent().props()).toEqual({
        hasError: false,
        hasMoreProfilesToLoad: false,
        isLoading: false,
        profilesPerPage: expect.any(Number),
        profiles: [],
      });
    });

    it.each([true, false])('passes down the error state', async hasError => {
      wrapper.setData({ hasSiteProfilesLoadingError: hasError });

      await wrapper.vm.$nextTick();

      expect(getSiteProfilesComponent().props('hasError')).toBe(hasError);
    });

    it.each([true, false])('passes down the pagination information', async hasNextPage => {
      wrapper.setData({ siteProfilesPageInfo: { hasNextPage } });

      await wrapper.vm.$nextTick();

      expect(getSiteProfilesComponent().props('hasMoreProfilesToLoad')).toBe(hasNextPage);
    });

    it.each([true, false])('passes down the loading state', loading => {
      createComponent({ mocks: { $apollo: { queries: { siteProfiles: { loading } } } } });

      expect(getSiteProfilesComponent().props('isLoading')).toBe(loading);
    });

    it('passes down the profiles data', async () => {
      const siteProfiles = [{}];
      wrapper.setData({ siteProfiles });

      await wrapper.vm.$nextTick();

      expect(getSiteProfilesComponent().props('profiles')).toBe(siteProfiles);
    });
  });
});
