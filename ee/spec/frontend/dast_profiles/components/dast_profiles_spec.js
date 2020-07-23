import { mount } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import DastProfiles from 'ee/dast_profiles/components/dast_profiles.vue';

const TEST_NEW_DAST_SITE_PROFILE_PATH = '/-/on_demand_scans/site_profiles/new';

describe('EE - DastProfiles', () => {
  let wrapper;

  const createComponent = () => {
    const defaultProps = {
      newDastSiteProfilePath: TEST_NEW_DAST_SITE_PROFILE_PATH,
    };

    wrapper = mount(DastProfiles, {
      propsData: defaultProps,
    });
  };

  const withinComponent = () => within(wrapper.element);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('header', () => {
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
});
