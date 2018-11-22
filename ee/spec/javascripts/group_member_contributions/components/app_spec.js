import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import AppComponent from 'ee/group_member_contributions/components/app.vue';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';
import { contributionsPath } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(AppComponent);

  const store = new GroupMemberStore(contributionsPath);

  return mountComponent(Component, {
    store,
  });
};

describe('AppComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('handleColumnClick', () => {
      it('calls store.sortMembers with columnName param', () => {
        spyOn(vm.store, 'sortMembers');

        const columnName = 'fullname';
        vm.handleColumnClick(columnName);

        expect(vm.store.sortMembers).toHaveBeenCalledWith(columnName);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `group-member-contributions-container`', () => {
      expect(vm.$el.classList.contains('group-member-contributions-container')).toBe(true);
    });

    it('renders header title element within component containe', () => {
      expect(vm.$el.querySelector('h3').innerText.trim()).toBe('Contributions per group member');
    });

    it('shows loading icon when isLoading prop is true', done => {
      vm.store.state.isLoading = true;
      vm.$nextTick()
        .then(() => {
          const loadingEl = vm.$el.querySelector('.loading-animation');

          expect(loadingEl).not.toBeNull();
          expect(loadingEl.querySelector('i').getAttribute('aria-label')).toBe(
            'Loading contribution stats for group members',
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders table container element', done => {
      vm.store.state.isLoading = false;
      vm.$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('table.table.gl-sortable')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
