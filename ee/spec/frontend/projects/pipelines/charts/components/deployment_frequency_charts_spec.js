import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CiCdAnalyticsCharts from '~/projects/pipelines/charts/components/ci_cd_analytics_charts.vue';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as Sentry from '~/sentry/wrapper';
import httpStatus from '~/lib/utils/http_status';
import DeploymentFrequencyCharts from 'ee_component/projects/pipelines/charts/components/deployment_frequency_charts.vue';

jest.mock('~/flash');
jest.mock('~/sentry/wrapper');

const lastWeekData = getJSONFixture(
  'api/project_analytics/daily_deployment_frequencies_for_last_week.json',
);
const lastMonthData = getJSONFixture(
  'api/project_analytics/daily_deployment_frequencies_for_last_month.json',
);
const last90DaysData = getJSONFixture(
  'api/project_analytics/daily_deployment_frequencies_for_last_90_days.json',
);

describe('ee_component/projects/pipelines/charts/components/deployment_frequency_charts.vue', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    wrapper = shallowMount(DeploymentFrequencyCharts, {
      provide: {
        projectPath: 'test/project',
      },
      stubs: { GlSprintf },
    });
  };

  // Initializes the mock endpoint to return a specific set of deployment
  // frequency data for a given "from" date.
  const setUpMockDeploymentFrequencies = ({ from, data }) => {
    mock
      .onGet(/projects\/test%2Fproject\/analytics\/deployment_frequency/, {
        params: {
          environment: 'production',
          interval: 'daily',
          per_page: 100,
          to: '2015-07-04T00:00:00+0000',
          from,
        },
      })
      .replyOnce(httpStatus.OK, data);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  const findHelpText = () => wrapper.find('[data-testid="help-text"]');
  const findDocLink = () => findHelpText().find(GlLink);

  describe('when there are no network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      setUpMockDeploymentFrequencies({
        from: '2015-06-27T00:00:00+0000',
        data: lastWeekData,
      });
      setUpMockDeploymentFrequencies({
        from: '2015-06-04T00:00:00+0000',
        data: lastMonthData,
      });
      setUpMockDeploymentFrequencies({
        from: '2015-04-05T00:00:00+0000',
        data: last90DaysData,
      });

      createComponent();

      await axios.waitForAll();
    });

    it('makes 3 GET requests - one for each chart', () => {
      expect(mock.history.get).toHaveLength(3);
    });

    it('converts the data from the API into data usable by the chart component', () => {
      const chartWrapper = wrapper.find(CiCdAnalyticsCharts);
      expect(chartWrapper.props().charts).toMatchSnapshot();
    });

    it('does not show a flash message', () => {
      expect(createFlash).not.toHaveBeenCalled();
    });

    it('renders description text', () => {
      expect(findHelpText().text()).toMatchInterpolatedText(
        'These charts display the frequency of deployments to the production environment, as part of the DORA 4 metrics. The environment must be named production for its data to appear in these charts. Learn more.',
      );
    });

    it('renders a link to the documentation', () => {
      expect(findDocLink().attributes().href).toBe(
        '/help/user/analytics/ci_cd_analytics.html#deployment-frequency-charts',
      );
    });
  });

  describe('when there are network errors', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);

      createComponent();

      await axios.waitForAll();
    });

    it('shows a flash message', () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while getting deployment frequency data',
      });
    });

    it('reports an error to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledTimes(1);

      const expectedErrorMessage = [
        'Something went wrong while getting deployment frequency data:',
        'Error: Request failed with status code 404',
        'Error: Request failed with status code 404',
        'Error: Request failed with status code 404',
      ].join('\n');

      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(expectedErrorMessage));
    });
  });
});
