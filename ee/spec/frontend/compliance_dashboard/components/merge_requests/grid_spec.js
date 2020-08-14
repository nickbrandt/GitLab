import { shallowMount } from '@vue/test-utils';

import MergeRequestsGrid from 'ee/compliance_dashboard/components/merge_requests/grid.vue';
import ApprovalStatus from 'ee/compliance_dashboard/components/merge_requests/approval_status.vue';
import BranchDetails from 'ee/compliance_dashboard/components/merge_requests/branch_details.vue';
import PipelineStatus from 'ee/compliance_dashboard/components/merge_requests/pipeline_status.vue';
import Approvers from 'ee/compliance_dashboard/components/merge_requests/approvers.vue';
import { createMergeRequests, createPipelineStatus } from '../../mock_data';

describe('MergeRequestsGrid component', () => {
  let wrapper;

  const findMergeRequests = () => wrapper.findAll('[data-testid="merge-request"]');
  const findTime = () => wrapper.find('time');
  const findApprovalStatus = () => wrapper.find(ApprovalStatus);
  const findPipelineStatus = () => wrapper.find(PipelineStatus);
  const findApprovers = () => wrapper.find(Approvers);
  const findBranchDetails = () => wrapper.find(BranchDetails);

  const createComponent = (mergeRequestProps = {}) => {
    return shallowMount(MergeRequestsGrid, {
      propsData: {
        mergeRequests: createMergeRequests({ count: 2, props: mergeRequestProps }),
        isLastPage: false,
      },
      stubs: {
        MergeRequest: {
          props: { mergeRequest: Object },
          template: `<div data-testid="merge-request">{{ mergeRequest.title }}</div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when intialized', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders a list of merge requests', () => {
      expect(findMergeRequests().length).toBe(2);
    });

    describe('approval status', () => {
      it('does not render if there is no approval status', () => {
        expect(findApprovalStatus().exists()).toBe(false);
      });

      it('renders if there is an approval status', () => {
        wrapper = createComponent({ approval_status: 'success' });
        expect(findApprovalStatus().exists()).toBe(true);
      });
    });

    describe('pipeline status', () => {
      it('does not render if there is no pipeline', () => {
        expect(findPipelineStatus().exists()).toBe(false);
      });

      it('renders if there is a pipeline', () => {
        wrapper = createComponent({ pipeline_status: createPipelineStatus('success') });
        expect(findPipelineStatus().exists()).toBe(true);
      });
    });

    describe('branch details', () => {
      it('does not render if there are no branch details', () => {
        expect(findBranchDetails().exists()).toBe(false);
      });

      it('renders if there are branch details', () => {
        wrapper = createComponent({ target_branch: 'master', source_branch: 'feature' });
        expect(findBranchDetails().exists()).toBe(true);
      });
    });

    it('renders the approvers list', () => {
      expect(findApprovers().exists()).toBe(true);
    });

    it('renders the "merged at" time', () => {
      expect(findTime().text()).toBe('merged 2 days ago');
    });
  });
});
