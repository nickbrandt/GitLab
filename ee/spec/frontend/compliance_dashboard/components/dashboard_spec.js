import { shallowMount } from '@vue/test-utils';

import ComplianceDashboard from 'ee/compliance_dashboard/components/dashboard.vue';
import { createMergeRequests } from '../mock_data';

describe('ComplianceDashboard component', () => {
  let wrapper;

  const findMergeRequests = () => wrapper.findAll('.merge-request');

  const createComponent = (props = {}) => {
    return shallowMount(ComplianceDashboard, {
      propsData: {
        mergeRequests: createMergeRequests({ count: 2 }),
        isLastPage: false,
        emptyStateSvgPath: 'empty.svg',
        ...props,
      },
      stubs: {
        MergeRequest: {
          props: { mergeRequest: Object },
          template: `<div class="merge-request">{{ mergeRequest.title }}</div>`,
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
