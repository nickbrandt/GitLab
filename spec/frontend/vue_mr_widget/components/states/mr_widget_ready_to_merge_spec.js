import Vue from 'vue';
import { GlLink } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { trimText } from '../../../helpers/text_helper';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import SquashBeforeMerge from '~/vue_merge_request_widget/components/states/squash_before_merge.vue';
import CommitsHeader from '~/vue_merge_request_widget/components/states/commits_header.vue';
import CommitEdit from '~/vue_merge_request_widget/components/states/commit_edit.vue';
import CommitMessageDropdown from '~/vue_merge_request_widget/components/states/commit_message_dropdown.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import { MWPS_MERGE_STRATEGY, MTWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import simplePoll from '~/lib/utils/simple_poll';

jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);
jest.mock('~/commons/nav/user_merge_requests', () => ({
  refreshUserMergeRequestCounts: jest.fn(),
}));

let wrapper;

const commitMessage = 'This is the commit message';
const squashCommitMessage = 'This is the squash commit message';
const commitMessageWithDescription = 'This is the commit message description';
const mockDataMr = {
  isPipelineActive: false,
  pipeline: null,
  isPipelineFailed: false,
  isPipelinePassing: false,
  isMergeAllowed: true,
  isApproved: true,
  onlyAllowMergeIfPipelineSucceeds: false,
  ffOnlyEnabled: false,
  hasCI: false,
  ciStatus: null,
  sha: '12345678',
  squash: false,
  squashIsEnabledByDefault: false,
  squashIsReadonly: false,
  squashIsSelected: false,
  commitMessage,
  squashCommitMessage,
  commitMessageWithDescription,
  shouldRemoveSourceBranch: true,
  canRemoveSourceBranch: false,
  targetBranch: 'master',
  preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
  availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
  mergeImmediatelyDocsPath: 'path/to/merge/immediately/docs',
};

const findMismatchShaBlock = () => wrapper.find('[data-testid="shaMismatchBlock"]');
const findFastForwardMessage = () => wrapper.find('[data-testid="mr-fast-forward-message"]');
const findModifyCommitMessageBtn = () =>
  wrapper.find('[data-testid="modify-commit-message-button"]');
const findRemoveSourceBranchInput = () => wrapper.find('#remove-source-branch-input');
const findResolveItemsMessage = () => wrapper.find('[data-testid="resolve-items-message"]');

const createTestService = () => ({
  merge: jest.fn(),
  poll: jest.fn().mockResolvedValue(),
});

const createComponent = (customMrData = {}, mountFn = shallowMount) => {
  return mountFn(ReadyToMerge, {
    propsData: {
      mr: { ...mockDataMr, ...customMrData },
      service: createTestService(),
    },
  });
};

describe('ReadyToMerge', () => {
  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe('isAutoMergeAvailable', () => {
      it('should return true when at least one merge strategy is available', () => {
        expect(wrapper.vm.isAutoMergeAvailable).toBe(true);
      });

      it('should return false when no merge strategies are available', () => {
        wrapper.vm.mr.availableAutoMergeStrategies = [];

        expect(wrapper.vm.isAutoMergeAvailable).toBe(false);
      });
    });

    describe('status', () => {
      it('defaults to success', () => {
        Vue.set(wrapper.mr, 'pipeline', true);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.status).toEqual('success');
      });

      it('returns failed when MR has CI but also has an unknown status', () => {
        Vue.set(wrapper.mr, 'hasCI', true);

        expect(wrapper.status).toEqual('failed');
      });

      it('returns default when MR has no pipeline', () => {
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.status).toEqual('success');
      });

      it('returns pending when pipeline is active', () => {
        Vue.set(wrapper.mr, 'pipeline', {});
        Vue.set(wrapper.mr, 'isPipelineActive', true);

        expect(wrapper.status).toEqual('pending');
      });

      it('returns failed when pipeline is failed', () => {
        Vue.set(wrapper.mr, 'pipeline', {});
        Vue.set(wrapper.mr, 'isPipelineFailed', true);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.status).toEqual('failed');
      });
    });

    describe('mergeButtonVariant', () => {
      it('defaults to success class', () => {
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.mergeButtonVariant).toEqual('success');
      });

      it('returns success class for success status', () => {
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);
        Vue.set(wrapper.mr, 'pipeline', true);

        expect(wrapper.mergeButtonVariant).toEqual('success');
      });

      it('returns info class for pending status', () => {
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', [MTWPS_MERGE_STRATEGY]);

        expect(wrapper.mergeButtonVariant).toEqual('info');
      });

      it('returns danger class for failed status', () => {
        wrapper.mr.hasCI = true;

        expect(wrapper.mergeButtonVariant).toEqual('danger');
      });
    });

    describe('status icon', () => {
      it('defaults to tick icon', () => {
        expect(wrapper.iconClass).toEqual('success');
      });

      it('shows tick for success status', () => {
        wrapper.mr.pipeline = true;

        expect(wrapper.iconClass).toEqual('success');
      });

      it('shows tick for pending status', () => {
        wrapper.mr.pipeline = {};
        wrapper.mr.isPipelineActive = true;

        expect(wrapper.iconClass).toEqual('success');
      });

      it('shows warning icon for failed status', () => {
        wrapper.mr.hasCI = true;

        expect(wrapper.iconClass).toEqual('warning');
      });

      it('shows warning icon for merge not allowed', () => {
        wrapper.mr.hasCI = true;

        expect(wrapper.iconClass).toEqual('warning');
      });
    });

    describe('mergeButtonText', () => {
      it('should return "Merge" when no auto merge strategies are available', () => {
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.mergeButtonText).toEqual('Merge');
      });

      it('should return "Merge in progress"', () => {
        Vue.set(wrapper, 'isMergingImmediately', true);

        expect(wrapper.mergeButtonText).toEqual('Merge in progress');
      });

      it('should return "Merge when pipeline succeeds" when the MWPS auto merge strategy is available', () => {
        Vue.set(wrapper, 'isMergingImmediately', false);
        Vue.set(wrapper.mr, 'preferredAutoMergeStrategy', MWPS_MERGE_STRATEGY);

        expect(wrapper.mergeButtonText).toEqual('Merge when pipeline succeeds');
      });
    });

    describe('autoMergeText', () => {
      it('should return Merge when pipeline succeeds', () => {
        Vue.set(wrapper.mr, 'preferredAutoMergeStrategy', MWPS_MERGE_STRATEGY);

        expect(wrapper.autoMergeText).toEqual('Merge when pipeline succeeds');
      });
    });

    describe('shouldShowMergeImmediatelyDropdown', () => {
      it('should return false if no pipeline is active', () => {
        Vue.set(wrapper.mr, 'isPipelineActive', false);
        Vue.set(wrapper.mr, 'onlyAllowMergeIfPipelineSucceeds', false);

        expect(wrapper.shouldShowMergeImmediatelyDropdown).toBe(false);
      });

      it('should return false if "Pipelines must succeed" is enabled for the current project', () => {
        Vue.set(wrapper.mr, 'isPipelineActive', true);
        Vue.set(wrapper.mr, 'onlyAllowMergeIfPipelineSucceeds', true);

        expect(wrapper.shouldShowMergeImmediatelyDropdown).toBe(false);
      });

      it('should return true if the MR\'s pipeline is active and "Pipelines must succeed" is not enabled for the current project', () => {
        Vue.set(wrapper.mr, 'isPipelineActive', true);
        Vue.set(wrapper.mr, 'onlyAllowMergeIfPipelineSucceeds', false);

        expect(wrapper.shouldShowMergeImmediatelyDropdown).toBe(true);
      });
    });

    describe('isMergeButtonDisabled', () => {
      it('should return false with initial data', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', true);

        expect(wrapper.isMergeButtonDisabled).toBe(false);
      });

      it('should return true when there is no commit message', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', true);
        Vue.set(wrapper, 'commitMessage', '');

        expect(wrapper.isMergeButtonDisabled).toBe(true);
      });

      it('should return true if merge is not allowed', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', false);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);
        Vue.set(wrapper.mr, 'onlyAllowMergeIfPipelineSucceeds', true);

        expect(wrapper.isMergeButtonDisabled).toBe(true);
      });

      it('should return true when the wrapper instance is making request', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', true);
        Vue.set(wrapper, 'isMakingRequest', true);

        expect(wrapper.isMergeButtonDisabled).toBe(true);
      });
    });

    describe('isMergeImmediatelyDangerous', () => {
      it('should always return false in CE', () => {
        expect(wrapper.isMergeImmediatelyDangerous).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('shouldShowMergeControls', () => {
      it('should return false when an external pipeline is running and required to succeed', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', false);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.shouldShowMergeControls).toBe(false);
      });

      it('should return true when the build succeeded or build not required to succeed', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', true);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', []);

        expect(wrapper.shouldShowMergeControls).toBe(true);
      });

      it('should return true when showing the MWPS button and a pipeline is running that needs to be successful', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', false);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', [MWPS_MERGE_STRATEGY]);

        expect(wrapper.shouldShowMergeControls).toBe(true);
      });

      it('should return true when showing the MWPS button but not required for the pipeline to succeed', () => {
        Vue.set(wrapper.mr, 'isMergeAllowed', true);
        Vue.set(wrapper.mr, 'availableAutoMergeStrategies', [MWPS_MERGE_STRATEGY]);

        expect(wrapper.shouldShowMergeControls).toBe(true);
      });
    });

    describe('updateMergeCommitMessage', () => {
      it('should revert flag and change commitMessage', () => {
        expect(wrapper.commitMessage).toEqual(commitMessage);
        wrapper.updateMergeCommitMessage(true);

        expect(wrapper.commitMessage).toEqual(commitMessageWithDescription);
        wrapper.updateMergeCommitMessage(false);

        expect(wrapper.commitMessage).toEqual(commitMessage);
      });
    });

    describe('handleMergeButtonClick', () => {
      const returnPromise = status =>
        new Promise(resolve => {
          resolve({
            data: {
              status,
            },
          });
        });

      it('should handle merge when pipeline succeeds', done => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest
          .spyOn(wrapper.service, 'merge')
          .mockReturnValue(returnPromise('merge_when_pipeline_succeeds'));
        wrapper.removeSourceBranch = false;
        wrapper.handleMergeButtonClick(true);

        setImmediate(() => {
          expect(wrapper.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');

          const params = wrapper.service.merge.mock.calls[0][0];

          expect(params).toEqual(
            expect.objectContaining({
              sha: wrapper.mr.sha,
              commit_message: wrapper.mr.commitMessage,
              should_remove_source_branch: false,
              auto_merge_strategy: 'merge_when_pipeline_succeeds',
            }),
          );
          done();
        });
      });

      it('should handle merge failed', done => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.service, 'merge').mockReturnValue(returnPromise('failed'));
        wrapper.handleMergeButtonClick(false, true);

        setImmediate(() => {
          expect(wrapper.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('FailedToMerge', undefined);

          const params = wrapper.service.merge.mock.calls[0][0];

          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.auto_merge_strategy).toBeUndefined();
          done();
        });
      });

      it('should handle merge action accepted case', done => {
        jest.spyOn(wrapper.service, 'merge').mockReturnValue(returnPromise('success'));
        jest.spyOn(wrapper, 'initiateMergePolling').mockImplementation(() => {});
        wrapper.handleMergeButtonClick();

        setImmediate(() => {
          expect(wrapper.isMakingRequest).toBeTruthy();
          expect(wrapper.initiateMergePolling).toHaveBeenCalled();

          const params = wrapper.service.merge.mock.calls[0][0];

          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.auto_merge_strategy).toBeUndefined();
          done();
        });
      });
    });

    describe('initiateMergePolling', () => {
      it('should call simplePoll', () => {
        wrapper.initiateMergePolling();

        expect(simplePoll).toHaveBeenCalledWith(expect.any(Function), { timeout: 0 });
      });

      it('should call handleMergePolling', () => {
        jest.spyOn(wrapper, 'handleMergePolling').mockImplementation(() => {});

        wrapper.initiateMergePolling();

        expect(wrapper.handleMergePolling).toHaveBeenCalled();
      });
    });

    describe('handleMergePolling', () => {
      const returnPromise = state =>
        new Promise(resolve => {
          resolve({
            data: {
              state,
              source_branch_exists: true,
            },
          });
        });

      beforeEach(() => {
        loadFixtures('merge_requests/merge_request_of_current_user.html');
      });

      it('should call start and stop polling when MR merged', done => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise('merged'));
        jest.spyOn(wrapper, 'initiateRemoveSourceBranchPolling').mockImplementation(() => {});

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.handleMergePolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );
        setImmediate(() => {
          expect(wrapper.service.poll).toHaveBeenCalled();
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          expect(eventHub.$emit).toHaveBeenCalledWith('FetchActionsContent');
          expect(wrapper.initiateRemoveSourceBranchPolling).toHaveBeenCalled();
          expect(refreshUserMergeRequestCounts).toHaveBeenCalled();
          expect(cpc).toBeFalsy();
          expect(spc).toBeTruthy();

          done();
        });
      });

      it('updates status box', done => {
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise('merged'));
        jest.spyOn(wrapper, 'initiateRemoveSourceBranchPolling').mockImplementation(() => {});

        wrapper.handleMergePolling(() => {}, () => {});

        setImmediate(() => {
          const statusBox = document.querySelector('.status-box');

          expect(statusBox.classList.contains('status-box-mr-merged')).toBeTruthy();
          expect(statusBox.textContent).toContain('Merged');

          done();
        });
      });

      it('hides close button', done => {
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise('merged'));
        jest.spyOn(wrapper, 'initiateRemoveSourceBranchPolling').mockImplementation(() => {});

        wrapper.handleMergePolling(() => {}, () => {});

        setImmediate(() => {
          expect(document.querySelector('.btn-close').classList.contains('hidden')).toBeTruthy();

          done();
        });
      });

      it('updates merge request count badge', done => {
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise('merged'));
        jest.spyOn(wrapper, 'initiateRemoveSourceBranchPolling').mockImplementation(() => {});

        wrapper.handleMergePolling(() => {}, () => {});

        setImmediate(() => {
          expect(document.querySelector('.js-merge-counter').textContent).toBe('0');

          done();
        });
      });

      it('should continue polling until MR is merged', done => {
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise('some_other_state'));
        jest.spyOn(wrapper, 'initiateRemoveSourceBranchPolling').mockImplementation(() => {});

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.handleMergePolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );
        setImmediate(() => {
          expect(cpc).toBeTruthy();
          expect(spc).toBeFalsy();

          done();
        });
      });
    });

    describe('initiateRemoveSourceBranchPolling', () => {
      it('should emit event and call simplePoll', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        wrapper.initiateRemoveSourceBranchPolling();

        expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [true]);
        expect(simplePoll).toHaveBeenCalled();
      });
    });

    describe('handleRemoveBranchPolling', () => {
      const returnPromise = state =>
        new Promise(resolve => {
          resolve({
            data: {
              source_branch_exists: state,
            },
          });
        });

      it('should call start and stop polling when MR merged', done => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise(false));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.handleRemoveBranchPolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );
        setImmediate(() => {
          expect(wrapper.service.poll).toHaveBeenCalled();

          const args = eventHub.$emit.mock.calls[0];

          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).toBeDefined();
          args[1]();

          expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [false]);

          expect(cpc).toBeFalsy();
          expect(spc).toBeTruthy();

          done();
        });
      });

      it('should continue polling until MR is merged', done => {
        jest.spyOn(wrapper.service, 'poll').mockReturnValue(returnPromise(true));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.handleRemoveBranchPolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );
        setImmediate(() => {
          expect(cpc).toBeTruthy();
          expect(spc).toBeFalsy();

          done();
        });
      });
    });
  });

  describe('Remove source branch checkbox', () => {
    describe('when user can merge but cannot delete branch', () => {
      it('should be disabled in the rendered output', () => {
        expect(findRemoveSourceBranchInput().exists()).toBe(false);
      });
    });

    describe('when user can merge and can delete branch', () => {
      beforeEach(() => {
        wrapper = createComponent({
          mr: { canRemoveSourceBranch: true },
        });
      });

      it('isRemoveSourceBranchButtonDisabled should be false', () => {
        expect(wrapper.isRemoveSourceBranchButtonDisabled).toBe(false);
      });

      it('removed source branch should be enabled in rendered output', () => {
        expect(findRemoveSourceBranchInput().exists()).toBe(true);
      });
    });
  });

  describe('render children components', () => {
    const findCheckboxElement = () => wrapper.find(SquashBeforeMerge);
    const findCommitsHeaderElement = () => wrapper.find(CommitsHeader);
    const findCommitEditElements = () => wrapper.findAll('[data-testid="squashLabel"]');
    const findCommitDropdownElement = () => wrapper.find(CommitMessageDropdown);
    const findFirstCommitEditLabel = () =>
      findCommitEditElements()
        .at(0)
        .props('label');

    describe('squash checkbox', () => {
      it('should be rendered when squash before merge is enabled and there is more than 1 commit', () => {
        createLocalComponent({
          mr: { commitsCount: 2, enableSquashBeforeMerge: true },
        });

        expect(findCheckboxElement().exists()).toBeTruthy();
      });

      it('should not be rendered when squash before merge is disabled', () => {
        createLocalComponent({ mr: { commitsCount: 2, enableSquashBeforeMerge: false } });

        expect(findCheckboxElement().exists()).toBeFalsy();
      });

      it('should not be rendered when there is only 1 commit', () => {
        createLocalComponent({ mr: { commitsCount: 1, enableSquashBeforeMerge: true } });

        expect(findCheckboxElement().exists()).toBeFalsy();
      });

      describe('squash options', () => {
        it.each`
          squashState           | state           | prop            | expectation
          ${'squashIsReadonly'} | ${'enabled'}    | ${'isDisabled'} | ${false}
          ${'squashIsSelected'} | ${'selected'}   | ${'value'}      | ${false}
          ${'squashIsSelected'} | ${'unselected'} | ${'value'}      | ${false}
        `(
          'is $state when squashIsReadonly returns $expectation ',
          ({ squashState, prop, expectation }) => {
            createLocalComponent({
              mr: { commitsCount: 2, enableSquashBeforeMerge: true, [squashState]: expectation },
            });

            expect(findCheckboxElement().props(prop)).toBe(expectation);
          },
        );

        it('is not rendered for "Do not allow" option', () => {
          createLocalComponent({
            mr: {
              commitsCount: 2,
              enableSquashBeforeMerge: true,
              squashIsReadonly: true,
              squashIsSelected: false,
            },
          });

          expect(findCheckboxElement().exists()).toBe(false);
        });
      });
    });

    describe('commits count collapsible header', () => {
      it('should be rendered when fast-forward is disabled', () => {
        createLocalComponent();

        expect(findCommitsHeaderElement().exists()).toBeTruthy();
      });

      describe('when fast-forward is enabled', () => {
        it('should be rendered if squash and squash before are enabled and there is more than 1 commit', () => {
          createLocalComponent({
            mr: {
              ffOnlyEnabled: true,
              enableSquashBeforeMerge: true,
              squashIsSelected: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeTruthy();
        });

        it('should not be rendered if squash before merge is disabled', () => {
          createLocalComponent({
            mr: {
              ffOnlyEnabled: true,
              enableSquashBeforeMerge: false,
              squash: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });

        it('should not be rendered if squash is disabled', () => {
          createLocalComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: false,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });

        it('should not be rendered if commits count is 1', () => {
          createLocalComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: true,
              enableSquashBeforeMerge: true,
              commitsCount: 1,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });
      });
    });

    describe('commits edit components', () => {
      const defaultMrData = {
        ...mockDataMr,
        ffOnlyEnabled: true,
        squash: false,
        enableSquashBeforeMerge: true,
        commitsCount: 2,
      };

      fdescribe('when fast-forward merge is enabled', () => {
        beforeEach(() => {
          wrapper = createComponent(defaultMrData, mount);
        });

        it('should not be rendered if squash is disabled', () => {
          expect(findCommitEditElements().length).toBe(0);
        });

        it('should not be rendered if squash before merge is disabled', async () => {
          wrapper.setProps({
            mr: { ...defaultMrData, squash: true, enableSquashBeforeMerge: false },
          });

          await wrapper.vm.$nextTick();

          expect(findCommitEditElements().length).toBe(0);
        });

        it('should not be rendered if there is only one commit', async () => {
          wrapper.setProps({
            mr: { ...defaultMrData, squash: true, commitsCount: 1 },
          });

          await wrapper.vm.$nextTick();

          expect(findCommitEditElements().length).toBe(0);
        });

        it('should have one edit component if squash is enabled and there is more than 1 commit', async () => {
          wrapper.setProps({
            mr: {
              ...defaultMrData,
              squashIsSelected: true,
              commitsCount: 2,
            },
          });

          await wrapper.vm.$nextTick();

          console.log(wrapper.html());

          expect(findCommitEditElements().length).toBe(1);
          expect(findFirstCommitEditLabel()).toBe('Squash commit message');
        });
      });

      it('should have one edit component when squash is disabled', () => {
        createLocalComponent();

        expect(findCommitEditElements().length).toBe(1);
      });

      it('should have two edit components when squash is enabled and there is more than 1 commit', () => {
        createLocalComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        expect(findCommitEditElements().length).toBe(2);
      });

      it('should have one edit components when squash is enabled and there is 1 commit only', () => {
        createLocalComponent({
          mr: {
            commitsCount: 1,
            squash: true,
            enableSquashBeforeMerge: true,
          },
        });

        expect(findCommitEditElements().length).toBe(1);
      });

      it('should have correct edit merge commit label', () => {
        createLocalComponent();

        expect(findFirstCommitEditLabel()).toBe('Merge commit message');
      });

      it('should have correct edit squash commit label', () => {
        createLocalComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        expect(findFirstCommitEditLabel()).toBe('Squash commit message');
      });
    });

    describe('commits dropdown', () => {
      beforeEach(() => {
        wrapper = createComponent({
          enableSquashBeforeMerge: false,
          squashIsSelected: true,
          commitsCount: 0,
        });
      });

      it('should not be rendered if squash is disabled', async () => {
        expect(findCommitDropdownElement().exists()).toBe(false);
      });

      it('should be rendered if squash is enabled and there is more than 1 commit', async () => {
        wrapper.setProps({
          mr: {
            ...mockDataMr,
            enableSquashBeforeMerge: true,
            squashIsSelected: true,
            commitsCount: 2,
          },
        });

        await wrapper.vm.$nextTick();

        expect(findCommitDropdownElement().exists()).toBe(true);
      });
    });
  });

  describe('Merge controls', () => {
    describe('when allowed to merge', () => {
      beforeEach(() => {
        wrapper = createComponent({ isMergeAllowed: true, canRemoveSourceBranch: true });
      });

      it('shows remove source branch checkbox', () => {
        expect(findRemoveSourceBranchInput().exists()).toBe(true);
      });

      it('shows modify commit message button', () => {
        expect(findModifyCommitMessageBtn().exists()).toBe(true);
      });

      it('does not show message about needing to resolve items', () => {
        expect(findResolveItemsMessage().exists()).toBe(false);
      });
    });

    describe('when not allowed to merge', () => {
      beforeEach(() => {
        wrapper = createComponent({ isMergeAllowed: false, availableAutoMergeStrategies: [] });
      });

      it('does not show remove source branch checkbox', () => {
        expect(findRemoveSourceBranchInput().exists()).toBe(false);
      });

      it('shows message to resolve all items before being allowed to merge', () => {
        expect(findResolveItemsMessage().exists()).toBe(true);
      });
    });
  });

  describe('Merge request project settings', () => {
    describe('when the merge commit merge method is enabled', () => {
      beforeEach(() => {
        wrapper = createComponent({ ffOnlyEnabled: false });
      });

      it('should not show fast forward message', () => {
        expect(findFastForwardMessage().exists()).toBe(false);
      });

      it('should show "Modify commit message" button', () => {
        expect(findModifyCommitMessageBtn().exists()).toBe(true);
      });
    });

    describe('when the fast-forward merge method is enabled', () => {
      beforeEach(() => {
        wrapper = createComponent({ ffOnlyEnabled: true });
      });

      it('should show fast forward message', () => {
        expect(findFastForwardMessage().exists()).toBe(true);
      });

      it('should not show "Modify commit message" button', () => {
        expect(findModifyCommitMessageBtn().exists()).toBe(false);
      });
    });
  });

  describe('with a mismatched SHA', () => {
    const diffPath = '/merge_requests/1/diffs';
    beforeEach(() => {
      wrapper = createComponent({
        isSHAMismatch: true,
        mergeRequestDiffsPath: diffPath,
      });
    });

    it('displays a warning message', () => {
      expect(findMismatchShaBlock().exists()).toBe(true);
    });

    it('warns the user to refresh to review', () => {
      expect(trimText(findMismatchShaBlock().text())).toBe(
        'New changes were added. Reload the page to review them',
      );
    });

    it('displays link to the diffs tab', () => {
      expect(
        findMismatchShaBlock()
          .find(GlLink)
          .attributes('href'),
      ).toBe(diffPath);
    });
  });
});
