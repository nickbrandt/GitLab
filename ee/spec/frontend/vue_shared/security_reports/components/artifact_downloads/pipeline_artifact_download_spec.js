import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Component from 'ee/vue_shared/security_reports/components/artifact_downloads/pipeline_artifact_download.vue';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from 'ee/vue_shared/security_reports/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  expectedDownloadDropdownProps,
  securityReportPipelineDownloadPathsQueryResponse,
} from 'jest/vue_shared/security_reports/mock_data';
import createFlash from '~/flash';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import securityReportPipelineDownloadPathsQuery from '~/vue_shared/security_reports/queries/security_report_pipeline_download_paths.query.graphql';

jest.mock('~/flash');

describe('Mr Artifact Download', () => {
  let wrapper;

  const defaultProps = {
    reportTypes: [REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION],
    targetProjectFullPath: '/path',
    pipelineIid: 123,
  };

  const createWrapper = ({ propsData, options }) => {
    wrapper = shallowMount(Component, {
      stubs: {
        SecurityReportDownloadDropdown,
      },
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      ...options,
    });
  };

  const pendingHandler = () => new Promise(() => {});
  const successHandler = () =>
    Promise.resolve({ data: securityReportPipelineDownloadPathsQueryResponse });
  const failureHandler = () => Promise.resolve({ errors: [{ message: 'some error' }] });
  const createMockApolloProvider = (handler) => {
    Vue.use(VueApollo);
    const requestHandlers = [[securityReportPipelineDownloadPathsQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const findDownloadDropdown = () => wrapper.find(SecurityReportDownloadDropdown);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('given the query is loading', () => {
    beforeEach(() => {
      createWrapper({
        options: {
          apolloProvider: createMockApolloProvider(pendingHandler),
        },
      });
    });

    it('loading is true', () => {
      expect(findDownloadDropdown().props('loading')).toBe(true);
    });
  });

  describe('given the query loads successfully', () => {
    beforeEach(() => {
      createWrapper({
        options: {
          apolloProvider: createMockApolloProvider(successHandler),
        },
      });
    });

    it('renders the download dropdown', () => {
      expect(findDownloadDropdown().props()).toEqual(expectedDownloadDropdownProps);
    });
  });

  describe('given the query fails', () => {
    beforeEach(() => {
      createWrapper({
        options: {
          apolloProvider: createMockApolloProvider(failureHandler),
        },
      });
    });

    it('calls createFlash correctly', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: Component.i18n.apiError,
        captureError: true,
        error: expect.any(Error),
      });
    });

    it('renders nothing', () => {
      expect(findDownloadDropdown().props('artifacts')).toEqual([]);
    });
  });
});
