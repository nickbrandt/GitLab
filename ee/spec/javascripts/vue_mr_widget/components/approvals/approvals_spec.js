import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import Approvals from 'ee/vue_merge_request_widget/components/approvals/approvals.vue';
import ApprovalsSummary from 'ee/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import ApprovalsSummaryOptional from 'ee/vue_merge_request_widget/components/approvals/approvals_summary_optional.vue';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import ApprovalsAuth from 'ee/vue_merge_request_widget/components/approvals/approvals_auth.vue';

import {
  FETCH_LOADING,
  FETCH_ERROR,
  APPROVE_ERROR,
  UNAPPROVE_ERROR,
} from 'ee/vue_merge_request_widget/components/approvals/messages';
import eventHub from '~/vue_merge_request_widget/event_hub';

const localVue = createLocalVue();
const TEST_HELP_PATH = 'help/path';
const TEST_PASSWORD = 'password';
const testApprovedBy = () => [1, 7, 10].map(id => ({ id }));
const testApprovals = () => ({
  has_approval_rules: true,
  approved: false,
  approved_by: testApprovedBy().map(user => ({ user })),
  approval_rules_left: [],
  approvals_left: 4,
  suggested_approvers: [],
  user_can_approve: true,
  user_has_approved: true,
  require_password_to_approve: false,
});
const testApprovalRulesResponse = () => ({ rules: [{ id: 2 }] });

// For some reason, the `localVue.nextTick` needs to be deferred
// or the timing doesn't work.
const tick = () => Promise.resolve().then(localVue.nextTick);
const waitForTick = done =>
  tick()
    .then(done)
    .catch(done.fail);

describe('EE MRWidget approvals', () => {
  let wrapper;
  let service;
  let mr;
  let createFlash;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(localVue.extend(Approvals), {
      propsData: {
        mr,
        service,
        ...props,
      },
      localVue,
      sync: false,
    });
  };

  const findAction = () => wrapper.find(GlButton);
  const findActionData = () => {
    const action = findAction();

    return !action.exists()
      ? null
      : {
          variant: action.attributes('variant'),
          inverted: action.classes('btn-inverted'),
          text: action.text(),
        };
  };
  const findSummary = () => wrapper.find(ApprovalsSummary);
  const findOptionalSummary = () => wrapper.find(ApprovalsSummaryOptional);
  const findFooter = () => wrapper.find(ApprovalsFooter);

  beforeEach(() => {
    service = jasmine.createSpyObj('MRWidgetService', {
      fetchApprovals: Promise.resolve(testApprovals()),
      fetchApprovalSettings: Promise.resolve(testApprovalRulesResponse()),
      approveMergeRequest: Promise.resolve(testApprovals()),
      unapproveMergeRequest: Promise.resolve(testApprovals()),
      approveMergeRequestWithAuth: Promise.resolve(testApprovals()),
    });
    mr = {
      ...jasmine.createSpyObj('Store', ['setApprovals', 'setApprovalRules']),
      approvalsHelpPath: TEST_HELP_PATH,
      approvals: testApprovals(),
      approvalRules: [],
      isOpen: true,
      state: 'open',
    };
    createFlash = spyOnDependency(Approvals, 'createFlash');

    spyOn(eventHub, '$emit');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when created', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows loading message', () => {
      expect(wrapper.text()).toContain(FETCH_LOADING);
    });

    it('fetches approvals', () => {
      expect(service.fetchApprovals).toHaveBeenCalled();
    });
  });

  describe('when fetch approvals success', () => {
    beforeEach(done => {
      service.fetchApprovals.and.returnValue(Promise.resolve());
      createComponent();
      waitForTick(done);
    });

    it('hides loading message', () => {
      expect(createFlash).not.toHaveBeenCalled();
      expect(wrapper.text()).not.toContain(FETCH_LOADING);
    });
  });

  describe('when fetch approvals error', () => {
    beforeEach(done => {
      service.fetchApprovals.and.returnValue(Promise.reject());
      createComponent();
      waitForTick(done);
    });

    it('still shows loading message', () => {
      expect(wrapper.text()).toContain(FETCH_LOADING);
    });

    it('flashes error', () => {
      expect(createFlash).toHaveBeenCalledWith(FETCH_ERROR);
    });
  });

  describe('action button', () => {
    describe('when mr is closed', () => {
      beforeEach(done => {
        mr.isOpen = false;
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = true;

        createComponent();
        waitForTick(done);
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user cannot approve', () => {
      beforeEach(done => {
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = false;

        createComponent();
        waitForTick(done);
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user can approve', () => {
      beforeEach(() => {
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = true;
      });

      describe('and MR is unapproved', () => {
        beforeEach(done => {
          createComponent();
          waitForTick(done);
        });

        it('approve action is rendered', () => {
          expect(findActionData()).toEqual({
            variant: 'primary',
            text: 'Approve',
            inverted: false,
          });
        });
      });

      describe('and MR is approved', () => {
        beforeEach(() => {
          mr.approvals.approved = true;
        });

        describe('with no approvers', () => {
          beforeEach(done => {
            mr.approvals.approved_by = [];
            createComponent();
            waitForTick(done);
          });

          it('approve action (with inverted) is rendered', () => {
            expect(findActionData()).toEqual({
              variant: 'primary',
              text: 'Approve',
              inverted: true,
            });
          });
        });

        describe('with approvers', () => {
          beforeEach(done => {
            mr.approvals.approved_by = [{ user: { id: 7 } }];
            createComponent();
            waitForTick(done);
          });

          it('approve additionally action is rendered', () => {
            expect(findActionData()).toEqual({
              variant: 'primary',
              text: 'Approve additionally',
              inverted: true,
            });
          });
        });
      });

      describe('when approve action is clicked', () => {
        beforeEach(done => {
          createComponent();
          waitForTick(done);
        });

        it('shows loading icon', done => {
          service.approveMergeRequest.and.callFake(() => new Promise(() => {}));
          const action = findAction();

          expect(action.find(GlLoadingIcon).exists()).toBe(false);

          action.vm.$emit('click');

          tick()
            .then(() => {
              expect(action.find(GlLoadingIcon).exists()).toBe(true);
            })
            .then(done)
            .catch(done.fail);
        });

        describe('and after loading', () => {
          beforeEach(done => {
            findAction().vm.$emit('click');
            waitForTick(done);
          });

          it('calls service approve', () => {
            expect(service.approveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });

          it('calls store setApprovals', () => {
            expect(mr.setApprovals).toHaveBeenCalledWith(testApprovals());
          });

          it('refetches the rules', () => {
            expect(service.fetchApprovalSettings).toHaveBeenCalled();
          });
        });

        describe('and error', () => {
          beforeEach(done => {
            service.approveMergeRequest.and.returnValue(Promise.reject());
            findAction().vm.$emit('click');
            waitForTick(done);
          });

          it('flashes error message', () => {
            expect(createFlash).toHaveBeenCalledWith(APPROVE_ERROR);
          });
        });
      });

      describe('when project requires password to approve', () => {
        beforeEach(done => {
          mr.approvals.require_password_to_approve = true;
          createComponent();
          waitForTick(done);
        });

        describe('when approve is clicked', () => {
          beforeEach(done => {
            findAction().vm.$emit('click');
            waitForTick(done);
          });

          describe('when emits approve', () => {
            let authReject;

            beforeEach(done => {
              service.approveMergeRequestWithAuth.and.returnValue(
                new Promise((resolve, reject) => {
                  authReject = reject;
                }),
              );
              wrapper.find(ApprovalsAuth).vm.$emit('approve', TEST_PASSWORD);
              waitForTick(done);
            });

            it('calls service when emits approve', () => {
              expect(service.approveMergeRequestWithAuth).toHaveBeenCalledWith(TEST_PASSWORD);
            });

            it('sets isLoading on auth', () => {
              expect(wrapper.find(ApprovalsAuth).props('isApproving')).toBe(true);
            });

            it('sets hasError when auth fails', done => {
              authReject({ response: { status: 401 } });

              tick()
                .then(() => {
                  expect(wrapper.find(ApprovalsAuth).props('hasError')).toBe(true);
                })
                .then(done)
                .catch(done.fail);
            });

            it('shows flash if general error', done => {
              authReject('something really bad!');

              tick()
                .then(() => {
                  expect(createFlash).toHaveBeenCalledWith(APPROVE_ERROR);
                })
                .then(done)
                .catch(done.fail);
            });
          });
        });
      });
    });

    describe('when user has approved', () => {
      beforeEach(done => {
        mr.approvals.user_has_approved = true;
        mr.approvals.user_can_approve = false;

        createComponent();
        waitForTick(done);
      });

      it('revoke action is rendered', () => {
        expect(findActionData()).toEqual({
          variant: 'warning',
          text: 'Revoke approval',
          inverted: true,
        });
      });

      describe('when revoke action is clicked', () => {
        describe('and successful', () => {
          beforeEach(done => {
            findAction().vm.$emit('click');
            waitForTick(done);
          });

          it('calls service unapprove', () => {
            expect(service.unapproveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });

          it('calls store setApprovals', () => {
            expect(mr.setApprovals).toHaveBeenCalledWith(testApprovals());
          });

          it('refetches the rules', () => {
            expect(service.fetchApprovalSettings).toHaveBeenCalled();
          });
        });

        describe('and error', () => {
          beforeEach(done => {
            service.unapproveMergeRequest.and.returnValue(Promise.reject());
            findAction().vm.$emit('click');
            waitForTick(done);
          });

          it('flashes error message', () => {
            expect(createFlash).toHaveBeenCalledWith(UNAPPROVE_ERROR);
          });
        });
      });
    });
  });

  describe('approvals optional summary', () => {
    describe('when no approvals required and no approvers', () => {
      beforeEach(() => {
        mr.approvals.approved_by = [];
        mr.approvals.approvals_required = 0;
        mr.approvals.user_has_approved = false;
      });

      describe('and can approve', () => {
        beforeEach(done => {
          mr.approvals.user_can_approve = true;

          createComponent();
          waitForTick(done);
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: true,
            helpPath: TEST_HELP_PATH,
          });
        });
      });

      describe('and cannot approve', () => {
        beforeEach(done => {
          mr.approvals.user_can_approve = false;

          createComponent();
          waitForTick(done);
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: false,
            helpPath: TEST_HELP_PATH,
          });
        });
      });
    });
  });

  describe('approvals summary', () => {
    beforeEach(done => {
      createComponent();
      waitForTick(done);
    });

    it('is rendered with props', () => {
      const expected = testApprovals();
      const summary = findSummary();

      expect(findOptionalSummary().exists()).toBe(false);
      expect(summary.exists()).toBe(true);
      expect(summary.props()).toEqual(
        jasmine.objectContaining({
          approvalsLeft: expected.approvals_left,
          rulesLeft: expected.approval_rules_left,
          approvers: testApprovedBy(),
        }),
      );
    });
  });

  describe('footer', () => {
    let footer;

    beforeEach(done => {
      createComponent();
      waitForTick(done);
    });

    beforeEach(() => {
      footer = findFooter();
    });

    it('is rendered with props', () => {
      expect(footer.exists()).toBe(true);
      expect(footer.props()).toEqual(
        jasmine.objectContaining({
          value: false,
          suggestedApprovers: mr.approvals.suggested_approvers,
          approvalRules: mr.approvalRules,
          isLoadingRules: false,
        }),
      );
    });

    describe('when opened', () => {
      describe('and loading', () => {
        beforeEach(done => {
          service.fetchApprovalSettings.and.callFake(() => new Promise(() => {}));
          footer.vm.$emit('input', true);
          waitForTick(done);
        });

        it('calls service fetch approval rules', () => {
          expect(service.fetchApprovalSettings).toHaveBeenCalled();
        });

        it('is loading rules', () => {
          expect(wrapper.vm.isLoadingRules).toBe(true);
          expect(footer.props('isLoadingRules')).toBe(true);
        });
      });

      describe('and finished loading', () => {
        beforeEach(done => {
          footer.vm.$emit('input', true);
          waitForTick(done);
        });

        it('sets approval rules', () => {
          expect(mr.setApprovalRules).toHaveBeenCalledWith(testApprovalRulesResponse());
        });

        it('shows footer', () => {
          expect(footer.props('value')).toBe(true);
        });

        describe('and closed', () => {
          beforeEach(done => {
            service.fetchApprovalSettings.calls.reset();
            footer.vm.$emit('input', false);
            waitForTick(done);
          });

          it('does not call service fetch approval rules', () => {
            expect(service.fetchApprovalSettings).not.toHaveBeenCalled();
          });

          it('hides approval rules', () => {
            expect(footer.props('value')).toBe(false);
          });
        });
      });
    });
  });
});
