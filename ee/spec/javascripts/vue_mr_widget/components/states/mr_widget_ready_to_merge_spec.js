import { shallowMount, createLocalVue } from '@vue/test-utils';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import {
  MWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  ATMTWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';

describe('ReadyToMerge', () => {
  const localVue = createLocalVue();
  let wrapper;
  let vm;

  const service = {
    merge: () => {},
    poll: () => {},
  };

  const mr = {
    isPipelineActive: false,
    pipeline: null,
    isPipelineFailed: false,
    isPipelinePassing: false,
    isMergeAllowed: true,
    onlyAllowMergeIfPipelineSucceeds: false,
    ffOnlyEnabled: false,
    hasCI: false,
    ciStatus: null,
    sha: '12345678',
    squash: false,
    commitMessage: 'This is the commit message',
    squashCommitMessage: 'This is the squash commit message',
    commitMessageWithDescription: 'This is the commit message description',
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
    targetBranch: 'master',
    preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
    availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
  };

  const factory = (mrUpdates = {}) => {
    wrapper = shallowMount(localVue.extend(ReadyToMerge), {
      propsData: {
        mr: { ...mr, ...mrUpdates },
        service,
      },
      localVue,
      sync: false,
    });

    ({ vm } = wrapper);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('mergeButtonText', () => {
      it('should return "Merge" when no auto merge strategies are available', () => {
        factory({ availableAutoMergeStrategies: [] });

        expect(vm.mergeButtonText).toEqual('Merge');
      });

      it('should return "Merge in progress"', () => {
        factory();
        localVue.set(vm, 'isMergingImmediately', true);

        expect(vm.mergeButtonText).toEqual('Merge in progress');
      });

      it('should return "Merge when pipeline succeeds" when the MWPS auto merge strategy is available', () => {
        factory({
          preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
        });

        expect(vm.mergeButtonText).toEqual('Merge when pipeline succeeds');
      });

      it('should return "Start merge train" when the merge train auto merge stategy is available and there is no existing merge train', () => {
        factory({
          preferredAutoMergeStrategy: MT_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.mergeButtonText).toEqual('Start merge train');
      });

      it('should return "Add to merge train" when the merge train auto merge stategy is available and a merge train already exists', () => {
        factory({
          preferredAutoMergeStrategy: MT_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.mergeButtonText).toEqual('Add to merge train');
      });

      it('should return "Start merge train when pipeline succeeds" when the ATMTWPS auto merge strategy is available and there is no existing merge train', () => {
        factory({
          preferredAutoMergeStrategy: ATMTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.mergeButtonText).toEqual('Start merge train when pipeline succeeds');
      });

      it('should return "Add to merge train when pipeline succeeds" when the ATMTWPS auto merge strategy is available and a merge train already exists', () => {
        factory({
          preferredAutoMergeStrategy: ATMTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.mergeButtonText).toEqual('Add to merge train when pipeline succeeds');
      });
    });

    describe('autoMergeText', () => {
      it('should return Merge when pipeline succeeds', () => {
        factory({ preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY });

        expect(vm.autoMergeText).toEqual('Merge when pipeline succeeds');
      });

      it('should return Start merge train when pipeline succeeds', () => {
        factory({
          preferredAutoMergeStrategy: ATMTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.autoMergeText).toEqual('Start merge train when pipeline succeeds');
      });

      it('should return Add to merge train when pipeline succeeds', () => {
        factory({
          preferredAutoMergeStrategy: ATMTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.autoMergeText).toEqual('Add to merge train when pipeline succeeds');
      });
    });
  });
});
