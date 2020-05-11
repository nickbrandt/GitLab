import Vue from 'vue';

import EpicHeader from 'ee/epic/components/epic_header.vue';
import createStore from 'ee/epic/store';
import { statusType } from 'ee/epic/constants';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicHeaderComponent', () => {
  let vm;
  let store;

  beforeEach(() => {
    const Component = Vue.extend(EpicHeader);

    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
    });
  });

  afterEach(() => {
    vm.$destroy();
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

    describe('showGitlabTeamMemberBadge', () => {
      test.each`
        isGitlabEmployeeValue | expected
        ${true}               | ${true}
        ${false}              | ${false}
      `(
        'returns $expected when `author.isGitlabEmployee` is $isGitlabEmployeeValue',
        ({ isGitlabEmployeeValue, expected }) => {
          vm.$store.state.author.isGitlabEmployee = isGitlabEmployeeValue;

          expect(vm.showGitlabTeamMemberBadge).toBe(expected);
        },
      );
    });
  });

  describe('template', () => {
    it('renders component container element with class `detail-page-header`', () => {
      expect(vm.$el.classList.contains('detail-page-header')).toBe(true);
      expect(vm.$el.querySelector('.detail-page-header-body')).not.toBeNull();
    });

    it('renders epic status icon and text elements', () => {
      const statusEl = vm.$el.querySelector('.issuable-status-box');

      expect(statusEl).not.toBeNull();
      expect(
        statusEl.querySelector('svg.ic-issue-open-m use').getAttribute('xlink:href'),
      ).toContain('issue-open-m');

      expect(statusEl.querySelector('span').innerText.trim()).toBe('Open');
    });

    it('renders epic author details element', () => {
      const metaEl = vm.$el.querySelector('.issuable-meta');

      expect(metaEl).not.toBeNull();
      expect(metaEl.querySelector('strong a.user-avatar-link')).not.toBeNull();
    });

    it('renders action buttons element', () => {
      const actionsEl = vm.$el.querySelector('.js-issuable-actions');

      expect(actionsEl).not.toBeNull();
      expect(actionsEl.querySelector('.js-btn-epic-action')).not.toBeNull();
      expect(actionsEl.querySelector('.js-btn-epic-action').innerText.trim()).toBe('Close epic');
    });

    it('renders toggle sidebar button element', () => {
      const toggleButtonEl = vm.$el.querySelector('button.js-sidebar-toggle');

      expect(toggleButtonEl).not.toBeNull();
      expect(toggleButtonEl.getAttribute('aria-label')).toBe('Toggle sidebar');
      expect(toggleButtonEl.classList.contains('d-block')).toBe(true);
      expect(toggleButtonEl.classList.contains('d-sm-none')).toBe(true);
      expect(toggleButtonEl.classList.contains('gutter-toggle')).toBe(true);
    });

    it('renders GitLab team member badge when `author.isGitlabEmployee` is `true`', () => {
      vm.$store.state.author.isGitlabEmployee = true;

      return vm.$nextTick().then(() => {
        expect(vm.$refs.gitlabTeamMemberBadge).not.toBeUndefined();
      });
    });
  });
});
