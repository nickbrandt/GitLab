import { shallowMount, createLocalVue } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';
import GroupRepositoryAnalytics from 'ee/analytics/repository_analytics/components/group_repository_analytics.vue';

const localVue = createLocalVue();

describe('Group repository analytics app', () => {
  useFakeDate();
  let wrapper;

  const defaultProps = {
    groupAnalyticsCoverageReportsPath: '/coverage.csv?ref_path=refs/heads/master',
  };

  const createComponent = () => {
    wrapper = shallowMount(GroupRepositoryAnalytics, {
      localVue,
      propsData: {
        ...defaultProps,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders button to download code coverage CSV report', () => {
    const reportButton = wrapper.find('[data-testid="group-code-coverage-csv-button"]');
    // Due to the fake_date helper, we can always expect today's date to be 2020-07-06
    // and one year ago to be 2019-07-06
    const expectedPath = `${defaultProps.groupAnalyticsCoverageReportsPath}&start_date=2019-07-06&end_date=2020-07-06`;

    expect(reportButton.exists()).toBe(true);
    expect(reportButton.attributes('href')).toBe(expectedPath);
  });
});
