import { shallowMount } from '@vue/test-utils';

import ComplianceDashboard from 'ee/compliance_dashboard/components/dashboard.vue';
import ApprovalStatus from 'ee/compliance_dashboard/components/approval_status.vue';
import PipelineStatus from 'ee/compliance_dashboard/components/pipeline_status.vue';
import Approvers from 'ee/compliance_dashboard/components/approvers.vue';
import { createMergeRequests } from '../mock_data';

describe('ComplianceDashboard component', () => {
  let wrapper;

  const findMergeRequests = () => wrapper.findAll('[data-testid="merge-request"]');
  const findTime = () => wrapper.find('time');
  const findApprovalStatus = () => wrapper.find(ApprovalStatus);
  const findPipelineStatus = () => wrapper.find(PipelineStatus);
  const findApprovers = () => wrapper.find(Approvers);

  const createComponent = (props = {}, options = {}) => {
    return shallowMount(ComplianceDashboard, {
      propsData: {
        mergeRequests: createMergeRequests({ count: 2, options }),
        isLastPage: false,
        emptyStateSvgPath: 'empty.svg',
        ...props,
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

  describe('when there are merge requests', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders a list of merge requests', () => {
      expect(findMergeRequests().length).toEqual(2);
    });

    describe('approval status', () => {
      it('does not render if there is no approval status', () => {
        expect(findApprovalStatus().exists()).toBe(false);
      });

      it('renders if there is an approval status', () => {
        wrapper = createComponent({}, { approvalStatus: 'success' });
        expect(findApprovalStatus().exists()).toBe(true);
      });
    });

    describe('pipeline status', () => {
      it('does not render if there is no pipeline', () => {
        expect(findPipelineStatus().exists()).toBe(false);
      });

      it('renders if there is a pipeline', () => {
        wrapper = createComponent({}, { addPipeline: true });
        expect(findPipelineStatus().exists()).toBe(true);
      });
    });

    it('renders the approvers list', () => {
      expect(findApprovers().exists()).toBe(true);
    });

    it('renders the "merged at" time', () => {
      expect(findTime().text()).toEqual('merged 2 days ago');
    });
  });

  describe('when there are no merge requests', () => {
    beforeEach(() => {
      wrapper = createComponent({ mergeRequests: [] });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('does not render merge requests', () => {
      expect(findMergeRequests().exists()).toEqual(false);
    });
  });
});
