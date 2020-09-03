import { mount, shallowMount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import { merge } from 'lodash';
import { GlDropdown } from '@gitlab/ui';
import DastProfiles from 'ee/dast_profiles/components/dast_profiles.vue';

const TEST_NEW_DAST_SCANNER_PROFILE_PATH = '/-/on_demand_scans/scanner_profiles/new';
const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';
const TEST_PROJECT_FULL_PATH = '/namespace/project';

describe('EE - DastProfiles', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      createNewProfilePaths: {
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
          scannerProfiles: {
            fetchMore: jest.fn().mockResolvedValue(),
          },
        },
        mutate: jest.fn().mockResolvedValue(),
        addSmartQuery: jest.fn(),
      },
    };

    const defaultProvide = {
      glFeatures: {
        securityOnDemandScansScannerProfiles: true,
      },
    };

    wrapper = mountFn(
      DastProfiles,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: defaultMocks,
          provide: defaultProvide,
        },
        options,
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mount);

  const withFeatureFlag = (featureFlagName, { enabled, disabled }) => {
    it.each([true, false])(`with ${featureFlagName} enabled: "%s"`, featureFlagStatus => {
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
  const getProfilesComponent = profileType => wrapper.find(`[data-testid="${profileType}List"]`);
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
      withFeatureFlag('securityOnDemandScansScannerProfiles', {
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
      tabName               | shouldBeSelectedByDefault
      ${'Site Profiles'}    | ${true}
      ${'Scanner Profiles'} | ${false}
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

  describe.each`
    description                | profileType
    ${'Site Profiles List'}    | ${'siteProfiles'}
    ${'Scanner Profiles List'} | ${'scannerProfiles'}
  `('$description', ({ profileType }) => {
    beforeEach(() => {
      createComponent();
    });

    it('passes down the correct default props', () => {
      expect(getProfilesComponent(profileType).props()).toEqual({
        errorMessage: '',
        errorDetails: [],
        hasMoreProfilesToLoad: false,
        isLoading: false,
        profilesPerPage: expect.any(Number),
        profiles: [],
        fields: expect.any(Array),
      });
    });

    it.each([true, false])('passes down the loading state when loading is "%s"', loading => {
      createComponent({ mocks: { $apollo: { queries: { [profileType]: { loading } } } } });

      expect(getProfilesComponent(profileType).props('isLoading')).toBe(loading);
    });

    it.each`
      givenData                                                                   | propName                   | expectedPropValue
      ${{ errorMessage: 'foo' }}                                                  | ${'errorMessage'}          | ${'foo'}
      ${{ profileTypes: { [profileType]: { pageInfo: { hasNextPage: true } } } }} | ${'hasMoreProfilesToLoad'} | ${true}
      ${{ profileTypes: { [profileType]: { profiles: [{ foo: 'bar' }] } } }}      | ${'profiles'}              | ${[{ foo: 'bar' }]}
    `('passes down $propName correctly', async ({ givenData, propName, expectedPropValue }) => {
      wrapper.setData(givenData);

      await wrapper.vm.$nextTick();

      expect(getProfilesComponent(profileType).props(propName)).toEqual(expectedPropValue);
    });

    it('fetches more results when "@load-more-profiles" is emitted', () => {
      const {
        $apollo: {
          queries: {
            [profileType]: { fetchMore },
          },
        },
      } = wrapper.vm;

      expect(fetchMore).not.toHaveBeenCalled();

      getProfilesComponent(profileType).vm.$emit('load-more-profiles');

      expect(fetchMore).toHaveBeenCalledTimes(1);
    });

    it('deletes profile when "@delete-profile" is emitted', () => {
      const {
        $apollo: { mutate },
      } = wrapper.vm;

      expect(mutate).not.toHaveBeenCalled();

      getProfilesComponent(profileType).vm.$emit('delete-profile');

      expect(mutate).toHaveBeenCalledTimes(1);
    });
  });
});
