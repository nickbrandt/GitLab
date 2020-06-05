import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';

import EpicBody from 'ee/epic/components/epic_body.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { initialRequest } from 'jest/issue_show/mock_data';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicBodyComponent', () => {
  let vm;
  let mock;

  beforeEach(() => {
    window.IntersectionObserver = class {
      disconnect = jest.fn();
      observe = jest.fn();
    };

    mock = new MockAdapter(axios);
    mock.onGet(`${TEST_HOST}/realtime_changes`).reply(200, initialRequest);

    const Component = Vue.extend(EpicBody);
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
    });
  });

  afterEach(() => {
    delete window.IntersectionObserver;
    mock.restore();
    vm.$destroy();
  });

  describe('template', () => {
    it('renders component container element with classes `issuable-details` & `content-block`', () => {
      expect(vm.$el.classList.contains('issuable-details')).toBe(true);
      expect(vm.$el.classList.contains('content-block')).toBe(true);
    });

    it('renders epic body container element with class `detail-page-description`', () => {
      expect(vm.$el.querySelector('.detail-page-description')).not.toBeNull();
    });

    it('renders epic body elements', () => {
      expect(vm.$el.querySelector('.title-container')).not.toBeNull();
      expect(vm.$el.querySelector('.description')).not.toBeNull();
    });
  });
});
