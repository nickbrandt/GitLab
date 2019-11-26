import { mount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'helpers/test_constants';

import CardSecurityDashboardApp from 'ee/vue_shared/security_reports/card_security_reports_app.vue';
import createStore from 'ee/security_dashboard/store';
import { trimText } from 'helpers/text_helper';

const localVue = createLocalVue();

const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;
const vulnerabilitiesSummaryEndpoint = `${TEST_HOST}/vulnerabilities_summary`;

describe('Card security reports app', () => {
  let wrapper;
  let mock;

  const runDate = new Date();
  runDate.setDate(runDate.getDate() - 7);

  const createComponent = props => {
    wrapper = mount(CardSecurityDashboardApp, {
      localVue,
      store: createStore(),
      sync: false,
      attachToDocument: true,
      stubs: ['security-dashboard-table'],
      propsData: {
        hasPipelineData: true,
        emptyStateIllustrationPath: `${TEST_HOST}/img`,
        securityDashboardHelpPath: `${TEST_HOST}/help_dashboard`,
        commit: {
          id: '1234adf',
          path: `${TEST_HOST}/commit`,
        },
        branch: {
          id: 'master',
          path: `${TEST_HOST}/branch`,
        },
        pipeline: {
          id: '55',
          created: runDate.toISOString(),
          path: `${TEST_HOST}/pipeline`,
        },
        triggeredBy: {
          path: `${TEST_HOST}/user`,
          avatarPath: `${TEST_HOST}/img`,
          name: 'TestUser',
        },
        project: {
          id: 123,
          name: 'my-project',
        },
        dashboardDocumentation: `${TEST_HOST}/dashboard_documentation`,
        emptyStateSvgPath: `/empty_state.svg`,
        vulnerabilityFeedbackHelpPath: `${TEST_HOST}/vulnerability_feedback_help`,
        vulnerabilitiesEndpoint,
        vulnerabilitiesSummaryEndpoint,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('Headline renders', () => {
    it('renders pipeline metadata information', () => {
      const element = wrapper.find('.card-header .js-security-dashboard-left');

      expect(trimText(element.text())).toBe('Pipeline #55 triggered 1 week ago by TestUser');

      const pipelineLink = element.find(`a[href="${TEST_HOST}/pipeline"]`);

      expect(pipelineLink).not.toBeNull();
      expect(pipelineLink.text()).toBe('#55');

      const userAvatarLink = element.find('a.user-avatar-link');

      expect(userAvatarLink).not.toBeNull();
      expect(userAvatarLink.attributes('href')).toBe(`${TEST_HOST}/user`);
      expect(userAvatarLink.find('img').attributes('src')).toBe(`${TEST_HOST}/img?width=24`);

      expect(userAvatarLink.text().trim()).toBe('TestUser');
    });

    it('renders branch and commit information', () => {
      const revInformation = wrapper.find('.card-header .js-security-dashboard-right');
      expect(revInformation.html()).toMatchSnapshot();
    });
  });

  describe('Dashboard renders properly', () => {
    const findDashboard = () => wrapper.find(CardSecurityDashboardApp);

    it('renders security dashboard', () => {
      const dashboard = findDashboard();
      expect(dashboard.exists()).toBe(true);
    });

    it('renders one filter less because projects filter is locked', () => {
      const dashboard = findDashboard();
      const filters = dashboard.findAll('.dashboard-filter');
      expect(filters.length).toBe(wrapper.vm.$store.state.filters.filters.length - 1);
    });
  });

  describe('Empty State renders correctly', () => {
    beforeEach(() => {
      createComponent({ hasPipelineData: false });
    });

    it('renders empty state component with correct props', () => {
      const emptyState = wrapper.find(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props()).toMatchSnapshot();
    });
  });
});
