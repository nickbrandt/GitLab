import Vue from 'vue';
import MockAdapater from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import component from 'ee/security_dashboard/components/security_dashboard_table.vue';
import createStore from 'ee/security_dashboard/store';
import { TEST_HOST } from 'spec/test_constants';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import waitForPromises from 'spec/helpers/wait_for_promises';

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
  let mock;
  let vm;

  beforeEach(() => {
    mock = new MockAdapater(axios);
    store = createStore();
    store.state.vulnerabilities.vulnerabilitiesEndpoint = vulnerabilitiesEndpoint;
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      store.dispatch('vulnerabilities/requestVulnerabilities');
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render 10 skeleton rows in the table', () => {
      expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(10);
    });
  });

  describe('with a list of vulnerabilities', () => {
    beforeEach(() => {
      mock.onGet(vulnerabilitiesEndpoint).replyOnce(200, mockDataVulnerabilities);
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render a row for each vulnerability', done => {
      waitForPromises()
        .then(() => {
          expect(vm.$el.querySelectorAll('.vulnerabilities-row')).toHaveLength(
            mockDataVulnerabilities.length,
          );
          done();
        })
        .catch(done.fail);
    });
  });

  describe('with no vulnerabilties', () => {
    beforeEach(() => {
      mock.onGet(vulnerabilitiesEndpoint).replyOnce(200, []);
      vm = mountComponentWithStore(Component, { store, props });
    });

    it('should render the empty state', done => {
      waitForPromises()
        .then(() => {
          expect(vm.$el.querySelector('.empty-state')).not.toBeNull();
          done();
        })
        .catch(done.fail);
    });
  });
});
