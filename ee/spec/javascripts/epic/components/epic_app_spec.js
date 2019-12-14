import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';

import EpicApp from 'ee/epic/components/epic_app.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import issueShowData from 'spec/issue_show/mock_data';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicAppComponent', () => {
  let vm;
  let mock;

  beforeEach(done => {
    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/realtime_changes`).reply(200, issueShowData.initialRequest);

    const Component = Vue.extend(EpicApp);
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
    });

    setTimeout(done);
  });

  afterEach(() => {
    mock.restore();
    vm.$destroy();
  });

  describe('template', () => {
    it('renders component container element with class `epic-page-container`', () => {
      expect(vm.$el.classList.contains('epic-page-container')).toBe(true);
    });
  });
});
