import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import { GlEmptyState, GlLoadingIcon, GlTab, GlTabs, GlAlert } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';

import { REPORT_STATUS } from 'ee/license_compliance/store/modules/list/constants';

import LicenseComplianceApp from 'ee/license_compliance/components/app.vue';
import DetectedLicensesTable from 'ee/license_compliance/components/detected_licenses_table.vue';
import PipelineInfo from 'ee/license_compliance/components/pipeline_info.vue';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';

import * as getters from 'ee/license_compliance/store/modules/list/getters';

import {
  approvedLicense,
  blacklistedLicense,
} from 'ee_jest/vue_shared/license_compliance/mock_data';

import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';

Vue.use(Vuex);

let wrapper;

const readLicensePoliciesEndpoint = `${TEST_HOST}/license_management`;
const managedLicenses = [approvedLicense, blacklistedLicense];
const licenses = [{}, {}];
const emptyStateSvgPath = '/';
const documentationPath = '/';

const noop = () => {};

const createComponent = ({ state, props, options }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        state: {
          managedLicenses,
        },
      },
      licenseList: {
        namespaced: true,
        state: {
          licenses,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
          },
          ...state,
        },
        actions: {
          fetchLicenses: noop,
        },
        getters,
      },
    },
  });

  wrapper = shallowMount(LicenseComplianceApp, {
    propsData: {
      emptyStateSvgPath,
      documentationPath,
      readLicensePoliciesEndpoint,
      ...props,
    },
    ...options,
    store: fakeStore,
  });
};

describe('Project Licenses', () => {
  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        state: { initialized: false },
      });
    });

    it('shows the loading component', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show the empty state component', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });
  });

  describe('when empty state', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.jobNotSetUp,
          },
        },
      });
    });

    it('shows the empty state component', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });

    it('does not show the loading component', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });
  });

  describe('when licensePolicyList feature flag is enabled', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.ok,
          },
        },
        options: {
          provide: {
            glFeatures: { licensePolicyList: true },
          },
        },
      });
    });

    it('does not render a policy violations alert', () => {
      expect(wrapper.find(GlAlert).exists()).toBe(false);
    });

    it('renders a "Detected in project" tab and a "Policies" tab', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(true);
      expect(wrapper.find(GlTab).exists()).toBe(true);
      expect(wrapper.findAll(GlTab)).toHaveLength(2);
    });

    it('it renders the "Detected in project" table', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(true);
    });

    it('it renders the "Policies" table', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(true);
    });

    it('renders the pipeline info', () => {
      expect(wrapper.find(PipelineInfo).exists()).toBe(true);
    });

    describe('when there are policy violations', () => {
      beforeEach(() => {
        createComponent({
          state: {
            initialized: true,
            licenses: [{ classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED }],
          },
        });
      });

      it('renders a policy violations alert', () => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
        expect(wrapper.find(GlAlert).text()).toContain(
          "Detected licenses that are out-of-compliance with the project's assigned policies",
        );
      });
    });
  });

  describe('when licensePolicyList feature flag is disabled', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.ok,
          },
        },
        options: {
          provide: {
            glFeatures: { licensePolicyList: false },
          },
        },
      });
    });

    it('only renders the "Detected in project" table', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(true);
      expect(wrapper.find(LicenseManagement).exists()).toBe(false);
    });

    it('renders no "Policies" table', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });

    it('renders the pipeline info', () => {
      expect(wrapper.find(PipelineInfo).exists()).toBe(true);
    });

    it('renders no tabs', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });
  });
});
