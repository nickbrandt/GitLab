import { shallowMount } from '@vue/test-utils';

import MergeRequest from 'ee/compliance_dashboard/components/merge_request.vue';
import { createMergeRequest, createPipelineStatus } from '../mock_data';

describe('MergeRequest component', () => {
  let wrapper;

  const findCiIcon = () => wrapper.find('.ci-icon');
  const findCiLink = () => wrapper.find('.controls').find('a');
  const findInfo = () => wrapper.find('.issuable-main-info');
  const findTime = () => wrapper.find('time');

  const createComponent = mergeRequest => {
    return shallowMount(MergeRequest, {
      propsData: {
        mergeRequest,
      },
      stubs: {
        CiIcon: {
          props: { status: Object },
          template: `<div class="ci-icon">{{ status.group }}</div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there is a merge request', () => {
    const mergeRequest = createMergeRequest();

    beforeEach(() => {
      wrapper = createComponent(mergeRequest);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the title', () => {
      expect(
        findInfo()
          .find('.title')
          .text(),
      ).toEqual(mergeRequest.title);
    });

    it('renders the issuable reference', () => {
      expect(
        findInfo()
          .find('span')
          .text(),
      ).toEqual(mergeRequest.issuable_reference);
    });

    it('renders the "merged at" time', () => {
      expect(findTime().text()).toEqual('merged 2 days ago');
    });

    it('does not link to a pipeline', () => {
      expect(findCiLink().exists()).toEqual(false);
    });

    describe('with a pipeline', () => {
      const pipeline = createPipelineStatus('success');

      beforeEach(() => {
        wrapper = createComponent(createMergeRequest({ pipeline }));
      });

      it('links to the pipeline', () => {
        expect(findCiLink().attributes('href')).toEqual(pipeline.details_path);
      });

      it('renders a CI icon with the pipeline status', () => {
        expect(findCiIcon().text()).toEqual(pipeline.group);
      });
    });
  });
});
