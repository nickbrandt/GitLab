import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';

import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import EpicHeader from 'ee/epic/components/epic_header.vue';
import createStore from 'ee/epic/store';
import { statusType } from 'ee/epic/constants';

import { mockEpicMeta, mockEpicData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EpicHeaderComponent', () => {
  let wrapper;
  let vm;
  let store;

  beforeEach(() => {
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    wrapper = shallowMount(EpicHeader, {
      localVue,
      store,
    });

    vm = wrapper.vm;
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('statusIcon', () => {
      it('returns string `issue-open-m` when `isEpicOpen` is true', () => {
        vm.$store.state.state = statusType.open;

        expect(vm.statusIcon).toBe('issue-open-m');
      });

      it('returns string `mobile-issue-close` when `isEpicOpen` is false', () => {
        vm.$store.state.state = statusType.close;

        expect(vm.statusIcon).toBe('mobile-issue-close');
      });
    });

    describe('statusText', () => {
      it('returns string `Open` when `isEpicOpen` is true', () => {
        vm.$store.state.state = statusType.open;

        expect(vm.statusText).toBe('Open');
      });

      it('returns string `Closed` when `isEpicOpen` is false', () => {
        vm.$store.state.state = statusType.close;

        expect(vm.statusText).toBe('Closed');
      });
    });

    describe('actionButtonClass', () => {
      it('returns default button classes along with `btn-close` when `isEpicOpen` is true', () => {
        vm.$store.state.state = statusType.open;

        expect(vm.actionButtonClass).toBe(
          'btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button btn-close',
        );
      });

      it('returns default button classes along with `btn-open` when `isEpicOpen` is false', () => {
        vm.$store.state.state = statusType.close;

        expect(vm.actionButtonClass).toBe(
          'btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button btn-open',
        );
      });
    });

    describe('actionButtonText', () => {
      it('returns string `Close epic` when `isEpicOpen` is true', () => {
        vm.$store.state.state = statusType.open;

        expect(vm.actionButtonText).toBe('Close epic');
      });

      it('returns string `Reopen epic` when `isEpicOpen` is false', () => {
        vm.$store.state.state = statusType.close;

        expect(vm.actionButtonText).toBe('Reopen epic');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `detail-page-header`', () => {
      expect(vm.$el.classList.contains('detail-page-header')).toBe(true);
      expect(vm.$el.querySelector('.detail-page-header-body')).not.toBeNull();
    });

    it('renders epic status icon and text elements', () => {
      const statusEl = wrapper.find('.issuable-status-box');

      expect(statusEl.exists()).toBe(true);
      expect(statusEl.find(GlIcon).props('name')).toBe('issue-open-m');
      expect(statusEl.find('span').text()).toBe('Open');
    });

    it('renders confidential icon when `confidential` prop is true', () => {
      vm.$store.state.confidential = true;

      return Vue.nextTick(() => {
        const iconEl = wrapper.find('.issuable-warning-icon').find(GlIcon);
        expect(iconEl.exists()).toBe(true);
        expect(iconEl.props('name')).toBe('eye-slash');
      });
    });

    it('renders epic author details element', () => {
      const metaEl = wrapper.find('.issuable-meta');

      expect(metaEl.exists()).toBe(true);
      expect(metaEl.find(TimeagoTooltip).exists()).toBe(true);
      expect(metaEl.find(UserAvatarLink).exists()).toBe(true);
    });

    it('renders action buttons element', () => {
      const actionsEl = vm.$el.querySelector('.js-issuable-actions');

      expect(actionsEl).not.toBeNull();
      expect(actionsEl.querySelector('.js-btn-epic-action')).not.toBeNull();
      expect(actionsEl.querySelector('.js-btn-epic-action').innerText.trim()).toBe('Close epic');
    });

    it('renders toggle sidebar button element', () => {
      const toggleButtonEl = wrapper.find('.js-sidebar-toggle');

      expect(toggleButtonEl.exists()).toBe(true);
      expect(toggleButtonEl.attributes('aria-label')).toBe('Toggle sidebar');
      expect(toggleButtonEl.classes()).toEqual(
        expect.arrayContaining([('d-block', 'd-sm-none', 'gutter-toggle')]),
      );
    });

    it('renders GitLab team member badge when `author.isGitlabEmployee` is `true`', () => {
      vm.$store.state.author.isGitlabEmployee = true;

      // Wait for dynamic imports to resolve
      return new Promise(setImmediate).then(() => {
        expect(vm.$refs.gitlabTeamMemberBadge).not.toBeUndefined();
      });
    });
  });
});
