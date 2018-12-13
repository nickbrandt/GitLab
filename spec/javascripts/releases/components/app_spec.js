import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import app from '~/releases/components/app.vue';
import createStore from '~/releases/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../store/helpers';
import { releases } from '../mock_data';

describe('Releases App ', () => {
  const Component = Vue.extend(app);
  let store;
  let vm;
  let mock;

  const props = {
    endpoint: 'endpoint.json',
    documentationLink: 'help/releases',
    illustrationPath: 'illustration/path',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
    mock.restore();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).replyOnce(200, [], {});
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders loading icon', done => {
      expect(vm.$el.querySelector('.js-loading')).not.toBeNull();
      expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
      expect(vm.$el.querySelector('.js-success-state')).toBeNull();

      setTimeout(() => {
        done();
      }, 0);
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, releases);
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders success state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).not.toBeNull();

        done();
      }, 0);
    });
  });

  describe('with empty request', () => {
    beforeEach(() => {
      mock.onGet(props.endpoint).reply(200, []);
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('renders empty state', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-loading')).toBeNull();
        expect(vm.$el.querySelector('.js-empty-state')).not.toBeNull();
        expect(vm.$el.querySelector('.js-success-state')).toBeNull();

        done();
      }, 0);
    });
  });
});
