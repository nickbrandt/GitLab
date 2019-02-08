import Vue from 'vue';

import component from 'ee/security_dashboard/components/security_dashboard_table.vue';
import createStore from 'ee/security_dashboard/store';
import { TEST_HOST } from 'spec/test_constants';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

import {
  RECEIVE_VULNERABILITIES_ERROR,
  RECEIVE_VULNERABILITIES_SUCCESS,
  REQUEST_VULNERABILITIES,
} from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';

import { resetStore } from '../helpers';
import mockDataVulnerabilities from '../store/vulnerabilities/data/mock_data_vulnerabilities.json';

describe('Security Dashboard Table', () => {
  const Component = Vue.extend(component);
  const vulnerabilitiesEndpoint = '/vulnerabilitiesEndpoint.json';
  const props = {
    dashboardDocumentation: TEST_HOST,
    emptyStateSvgPath: TEST_HOST,
  };
  let store;
  let vm;

  beforeEach(() => {
    store = createStore();
    store.state.vulnerabilities.vulnerabilitiesEndpoint = vulnerabilitiesEndpoint;
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${REQUEST_VULNERABILITIES}`);
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(10);
    });
  });

  describe('with a list of vulnerabilities', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
        vulnerabilities: mockDataVulnerabilities,
      });
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render a row for each vulnerability', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(
        mockDataVulnerabilities.length,
      );
    });
  });

  describe('with no vulnerabilties', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, { vulnerabilities: [] });
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render the empty state', () => {
      expect(vm.$el.querySelector('.empty-state')).not.toBeNull();
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_ERROR}`);
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should not render the empty state', () => {
      expect(vm.$el.querySelector('.empty-state')).toBeNull();
    });

    it('should render the error alert', () => {
      expect(vm.$el.querySelector('.flash-alert')).not.toBeNull();
    });
  });
});
