import Vue from 'vue';
import mrWidgetApprovals from '~/vue_merge_request_widget/ee/components/approvals/mr_widget_approvals';
import Store from '~/vue_merge_request_widget/ee/stores/mr_widget_store';
import Service from '~/vue_merge_request_widget/ee/services/mr_widget_service';
import { approvalsData } from '../../../mock_data';

function queryTestableElements($el) {
  return {
    requiredText: $el.querySelector('.approvals-required-text').textContent,
    button: $el.querySelector('.approve-btn'),
    footer: $el.querySelector('.approvals-footer'),
    suggested: [...$el.querySelectorAll('.approvals-body img.avatar')],
    approvers: [...$el.querySelectorAll('.approvals-footer img.avatar')],
  };
}

describe('mrWidgetApprovals', () => {
  let MRWidgetApprovalsComponent;
  let store;
  let service;
  let mountComponent;
  let vm;

  beforeEach(() => {
    MRWidgetApprovalsComponent = Vue.extend(mrWidgetApprovals);
    store = new Store(approvalsData);
    service = new Service('');

    mountComponent = propsData => new MRWidgetApprovalsComponent({
      propsData,
    }).$mount();
  });

  describe('with no approvers', () => {
    beforeEach(() => {
      const newData = Object.assign({}, approvalsData.approvals);
      newData.approvals_left = 2;
      newData.approved_by = [];
      newData.user_has_approved = false;

      store.setApprovals(newData);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    it('requires 2 more approvals', () => {
      const { requiredText, button, footer, suggested } = queryTestableElements(vm.$el);

      expect(requiredText).toMatch('Requires 2 more approvals');
      expect(button).toBeDefined();
      expect(footer).toBeNull();
      expect(suggested[0].src).toMatch('/suggested_avatar_url');
      expect(suggested[1].src).toMatch('/suggested_avatar_url');
    });
  });

  describe('with 1 approver and 1 left', () => {
    beforeEach(() => {
      const newData = Object.assign({}, approvalsData.approvals);
      newData.approvals_left = 1;
      newData.approved_by = [newData.approved_by[0]];
      newData.user_has_approved = false;

      store.setApprovals(newData);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    it('requires 1 more approval', () => {
      const { requiredText, button, approvers, suggested } = queryTestableElements(vm.$el);

      expect(requiredText).toMatch('Requires 1 more approval');
      expect(button).toBeDefined();
      expect(suggested[0].src).toMatch('/suggested_avatar_url');
      expect(suggested[1].src).toMatch('/suggested_avatar_url');
      expect(approvers[0].src).toMatch('/approver_avatar_url');
      expect(approvers.length).toEqual(1);
    });
  });

  describe('with 2 approvers, none left', () => {
    beforeEach(() => {
      vm = mountComponent({
        mr: store,
        service,
      });
    });

    it('renders an approved state', () => {
      const { requiredText, button, approvers, suggested } = queryTestableElements(vm.$el);

      expect(requiredText).toMatch('Requires 0 more approvals');
      expect(button).toBeNull();
      expect(suggested[0].src).toMatch('/suggested_avatar_url');
      expect(suggested[1].src).toMatch('/suggested_avatar_url');
      expect(approvers[0].src).toMatch('/approver_avatar_url');
      expect(approvers[1].src).toMatch('/approver_avatar_url');
    });
  });

  describe('user cannot approve', () => {
    beforeEach(() => {
      const newData = Object.assign({}, approvalsData.approvals);
      newData.user_can_approve = false;

      store.setApprovals(newData);

      vm = mountComponent({
        mr: store,
        service,
      });
    });

    it('does not show approve button', () => {
      const { button } = queryTestableElements(vm.$el);

      expect(button).toBeNull();
    });
  });
});
