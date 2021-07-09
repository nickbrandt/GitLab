import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import CiCdAnalyticsApp from 'ee/analytics/group_ci_cd_analytics/components/app.vue';
import ReleaseStatsCard from 'ee/analytics/group_ci_cd_analytics/components/release_stats_card.vue';
import DeploymentFrequencyCharts from 'ee/dora/components/deployment_frequency_charts.vue';
import LeadTimeCharts from 'ee/dora/components/lead_time_charts.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { getParameterValues } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('ee/analytics/group_ci_cd_analytics/components/app.vue', () => {
  let wrapper;

  beforeEach(() => {
    getParameterValues.mockReturnValue([]);
  });

  const createComponent = (mountOptions = {}) => {
    wrapper = shallowMount(
      CiCdAnalyticsApp,
      merge(
        {
          provide: {
            shouldRenderDoraCharts: true,
          },
        },
        mountOptions,
      ),
    );
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabAtIndex = (index) => findAllGlTabs().at(index);

  describe('tabs', () => {
    describe('when the DORA charts are available', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders tabs in the correct order', () => {
        expect(findGlTabs().exists()).toBe(true);
        expect(findAllGlTabs().length).toBe(3);
        expect(findGlTabAtIndex(0).attributes('title')).toBe('Release statistics');
        expect(findGlTabAtIndex(1).attributes('title')).toBe('Deployment frequency');
        expect(findGlTabAtIndex(2).attributes('title')).toBe('Lead time');
      });
    });

    describe('when the DORA charts are not available', () => {
      beforeEach(() => {
        createComponent({ provide: { shouldRenderDoraCharts: false } });
      });

      it('does not render any tabs', () => {
        expect(findGlTabs().exists()).toBe(false);
      });

      it('renders the release statistics component', () => {
        expect(wrapper.findComponent(ReleaseStatsCard).exists()).toBe(true);
      });
    });
  });

  describe('release statistics', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the release statistics component inside the first tab', () => {
      expect(findGlTabAtIndex(0).findComponent(ReleaseStatsCard).exists()).toBe(true);
    });
  });

  describe('deployment frequency', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the deployment frequency component inside the second tab', () => {
      expect(findGlTabAtIndex(1).findComponent(DeploymentFrequencyCharts).exists()).toBe(true);
    });
  });

  describe('lead time', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the lead time component inside the third tab', () => {
      expect(findGlTabAtIndex(2).findComponent(LeadTimeCharts).exists()).toBe(true);
    });
  });

  describe('when provided with a query param', () => {
    it.each`
      tab                       | index
      ${'release-statistics'}   | ${'0'}
      ${'deployment-frequency'} | ${'1'}
      ${'lead-time'}            | ${'2'}
      ${'fake'}                 | ${'0'}
      ${''}                     | ${'0'}
    `('shows the correct tab for URL parameter "$tab"', ({ tab, index }) => {
      setWindowLocation(`${TEST_HOST}/groups/gitlab-org/gitlab/-/analytics/ci_cd?tab=${tab}`);
      getParameterValues.mockImplementation((name) => {
        expect(name).toBe('tab');
        return tab ? [tab] : [];
      });
      createComponent();
      expect(findGlTabs().attributes('value')).toBe(index);
    });
  });
});
