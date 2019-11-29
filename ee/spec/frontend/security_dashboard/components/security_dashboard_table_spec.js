import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';

import SecurityDashboardTable from 'ee/security_dashboard/components/security_dashboard_table.vue';
import SecurityDashboardTableRow from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import createStore from 'ee/security_dashboard/store';

import {
  RECEIVE_VULNERABILITIES_ERROR,
  RECEIVE_VULNERABILITIES_SUCCESS,
  REQUEST_VULNERABILITIES,
} from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';

import mockDataVulnerabilities from '../store/vulnerabilities/data/mock_data_vulnerabilities.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Security Dashboard Table', () => {
  const vulnerabilitiesEndpoint = '/vulnerabilitiesEndpoint.json';
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore();
    wrapper = shallowMount(SecurityDashboardTable, {
      localVue,
      store,
      sync: false,
    });
    store.state.vulnerabilities.vulnerabilitiesEndpoint = vulnerabilitiesEndpoint;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${REQUEST_VULNERABILITIES}`);
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(wrapper.findAll(SecurityDashboardTableRow).length).toEqual(10);
    });
  });

  describe('with a list of vulnerabilities', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: mockDataVulnerabilities,
        pageInfo: {},
      });
    });

    it('should render a row for each vulnerability', () => {
      expect(wrapper.findAll(SecurityDashboardTableRow).length).toEqual(
        mockDataVulnerabilities.length,
      );
    });
  });

  describe('with no vulnerabilties', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: [],
        pageInfo: {},
      });
    });

    it('should render the empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_ERROR}`);
    });

    it('should not render the empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    });

    it('should render the error alert', () => {
      expect(wrapper.find('.flash-alert').exists()).toBe(true);
    });
  });

  describe('with a custom empty state', () => {
    beforeEach(() => {
      wrapper = shallowMount(SecurityDashboardTable, {
        localVue,
        store,
        sync: false,
        slots: {
          emptyState: '<div class="customEmptyState">Hello World</div>',
        },
      });

      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: [],
        pageInfo: {},
      });
    });

    it('should render the custom empty state', () => {
      expect(wrapper.find('.customEmptyState').exists()).toBe(true);
    });
  });
});
