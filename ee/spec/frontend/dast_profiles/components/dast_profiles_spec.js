import { mount, shallowMount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import { merge } from 'lodash';
import { GlDropdown } from '@gitlab/ui';
import DastProfiles from 'ee/dast_profiles/components/dast_profiles.vue';
import DastProfilesList from 'ee/dast_profiles/components/dast_profiles_list.vue';

const TEST_NEW_DAST_SCANNER_PROFILE_PATH = '/-/on_demand_scans/scanner_profiles/new';
const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';
const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('EE - DastProfiles', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      newProfilePaths: {
        scannerProfile: TEST_NEW_DAST_SCANNER_PROFILE_PATH,
        siteProfile: TEST_NEW_DAST_SITE_PROFILE_PATH,
      },
      projectFullPath: TEST_PROJECT_FULL_PATH,
    };

    const defaultMocks = {
      $apollo: {
        queries: {
          siteProfiles: {
            fetchMore: jest.fn().mockResolvedValue(),
          },
        },
        mutate: jest.fn().mockResolvedValue(),
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

  const withFeatureFlag = (featureFlagName, { enabled, disabled }) => {
    describe.each([true, false])(`with ${featureFlagName} enabled: "%s"`, featureFlagStatus => {
      createComponent({
        provide: {
          glFeatures: {
            [featureFlagName]: featureFlagStatus,
          },
        },
      });

      if (featureFlagStatus) {
        enabled();
      } else {
        disabled();
      }
    });
  };

  const withinComponent = () => within(wrapper.element);
  const getSiteProfilesComponent = () => wrapper.find(DastProfilesList);
  const getDropdownComponent = () => wrapper.find(GlDropdown);
  const getSiteProfilesDropdownItem = text =>
    within(getDropdownComponent().element).queryByText(text);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('header', () => {
    it('shows a heading that describes the purpose of the page', () => {
      createFullComponent();

      const heading = withinComponent().getByRole('heading', { name: /manage profiles/i });

      expect(heading).not.toBe(null);
    });

    it('has a "New Profile" dropdown menu', () => {
      createComponent();

      expect(getDropdownComponent().props('text')).toBe('New Profile');
    });

    it(`shows a "Site Profile" dropdown item that links to ${TEST_NEW_DAST_SITE_PROFILE_PATH}`, () => {
      createComponent();

      expect(getSiteProfilesDropdownItem('Site Profile').getAttribute('href')).toBe(
        TEST_NEW_DAST_SITE_PROFILE_PATH,
      );
    });

    describe(`shows a "Scanner Profile" dropdown item that links to ${TEST_NEW_DAST_SCANNER_PROFILE_PATH}`, () => {
      withFeatureFlag('onDemandScansScannerProfiles', {
        enabled: () => {
          expect(getSiteProfilesDropdownItem('Scanner Profile').getAttribute('href')).toBe(
            TEST_NEW_DAST_SCANNER_PROFILE_PATH,
          );
        },
        disabled: () => {
          expect(getSiteProfilesDropdownItem('Scanner Profile')).toBe(null);
        },
      });
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
        errorMessage: '',
        errorDetails: [],
        hasMoreProfilesToLoad: false,
        isLoading: false,
        profilesPerPage: expect.any(Number),
        profiles: [],
      });
    });

    it.each([true, false])('passes down the loading state', loading => {
      createComponent({ mocks: { $apollo: { queries: { siteProfiles: { loading } } } } });

      expect(getSiteProfilesComponent().props('isLoading')).toBe(loading);
    });

    it.each`
      givenData                                          | propName                   | expectedPropValue
      ${{ errorMessage: 'foo' }}                         | ${'errorMessage'}          | ${'foo'}
      ${{ siteProfilesPageInfo: { hasNextPage: true } }} | ${'hasMoreProfilesToLoad'} | ${true}
      ${{ siteProfiles: [{ foo: 'bar' }] }}              | ${'profiles'}              | ${[{ foo: 'bar' }]}
    `('passes down $propName correctly', async ({ givenData, propName, expectedPropValue }) => {
      wrapper.setData(givenData);

      await wrapper.vm.$nextTick();

      expect(getSiteProfilesComponent().props(propName)).toEqual(expectedPropValue);
    });

    it('fetches more results when "@loadMoreProfiles" is emitted', () => {
      const {
        $apollo: {
          queries: {
            siteProfiles: { fetchMore },
          },
        },
      } = wrapper.vm;

      expect(fetchMore).not.toHaveBeenCalled();

      getSiteProfilesComponent().vm.$emit('loadMoreProfiles');

      expect(fetchMore).toHaveBeenCalledTimes(1);
    });

    it('deletes profile when "@deleteProfile" is emitted', () => {
      const {
        $apollo: { mutate },
      } = wrapper.vm;

      expect(mutate).not.toHaveBeenCalled();

      getSiteProfilesComponent().vm.$emit('deleteProfile');

      expect(mutate).toHaveBeenCalledTimes(1);
    });
  });
});
