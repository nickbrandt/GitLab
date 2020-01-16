import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'helpers/test_constants';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import store from 'ee/codequality_report/store';
import { parsedIssues, unparsedIssues } from './mock_data';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

jest.mock('~/flash', () => jest.fn());

describe('Codequality report app', () => {
  let wrapper;
  let mock;

  const codequalityReportDownloadPath = `${TEST_HOST}/codequality_report`;

  const createComponent = (props = {}) => {
    wrapper = mount(CodequalityReportApp, {
      store,
      propsData: {
        codequalityReportDownloadPath,
        blobPath: '/root/test-codequality/blob/feature-branch',
        ...props,
      },
    });
  };

  const findStatus = () => wrapper.find('.js-code-text');
  const findSuccessIcon = () => wrapper.find('.js-ci-status-icon-success');
  const findWarningIcon = () => wrapper.find('.js-ci-status-icon-warning');

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading state', () => {
      expect(findStatus().text()).toBe('Loading codeclimate report');
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      mock.onGet(codequalityReportDownloadPath).reply(500);
      createComponent();

      return waitForPromises();
    });

    it('shows a warning icon and error message', () => {
      expect(findWarningIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('Failed to load codeclimate report');
    });

    it('shows a flash message', () => {
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('when there are codequality issues', () => {
    beforeEach(() => {
      mock.onGet(codequalityReportDownloadPath).reply(200, unparsedIssues);
      createComponent();

      return waitForPromises();
    });

    it('renders the codequality issues', () => {
      const expectedIssueTotal = parsedIssues.length;

      expect(wrapper.vm.$store.state.allCodequalityIssues).toEqual(parsedIssues);
      expect(findStatus().text()).toBe(`Found ${expectedIssueTotal} code quality issues`);
      expect(wrapper.findAll('.report-block-list-issue').length).toBe(expectedIssueTotal);
    });
  });

  describe('when there are no codequality issues', () => {
    beforeEach(() => {
      mock.onGet(codequalityReportDownloadPath).reply(200, []);
      createComponent();

      return waitForPromises();
    });

    it('shows a message that no codequality issues were found', () => {
      expect(wrapper.vm.$store.state.allCodequalityIssues).toEqual([]);
      expect(findSuccessIcon().exists()).toBe(true);
      expect(findStatus().text()).toBe('No code quality issues found');
      expect(wrapper.findAll('.report-block-list-issue').length).toBe(0);
    });
  });
});
