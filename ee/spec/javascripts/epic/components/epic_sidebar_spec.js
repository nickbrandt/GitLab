import Vue from 'vue';

import EpicSidebar from 'ee/epic/components/epic_sidebar.vue';
import createStore from 'ee/epic/store';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicSidebarComponent', () => {
  const originalUserId = gon.current_user_id;
  let vm;
  let store;

  beforeEach(done => {
    const Component = Vue.extend(EpicSidebar);
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
    });

    setTimeout(done);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    beforeAll(() => {
      gon.current_user_id = 1;
    });

    afterAll(() => {
      gon.current_user_id = originalUserId;
    });

    it('renders component container element with classes `right-sidebar-expanded`, `right-sidebar` & `epic-sidebar`', done => {
      store.dispatch('toggleSidebarFlag', false);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('right-sidebar-expanded')).toBe(true);
          expect(vm.$el.classList.contains('right-sidebar')).toBe(true);
          expect(vm.$el.classList.contains('epic-sidebar')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders header container element with classes `issuable-sidebar` & `js-issuable-update`', () => {
      expect(vm.$el.querySelector('.issuable-sidebar.js-issuable-update')).not.toBeNull();
    });

    it('renders Todo toggle button element when sidebar is collapsed and user is signed in', done => {
      store.dispatch('toggleSidebarFlag', true);

      vm.$nextTick()
        .then(() => {
          const todoBlockEl = vm.$el.querySelector('.block.todo');

          expect(todoBlockEl).not.toBeNull();
          expect(todoBlockEl.querySelector('button.btn-todo')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
