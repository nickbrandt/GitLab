import { mount, createLocalVue } from '@vue/test-utils';
import MergeTrainPositionIndicator from 'ee/vue_merge_request_widget/components/merge_train_position_indicator.vue';
import VisualReviewAppLink from 'ee/vue_merge_request_widget/components/visual_review_app_link.vue';
import { mockStore } from 'spec/vue_mr_widget/mock_data';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import { MT_MERGE_STRATEGY, MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';

describe('MrWidgetPipelineContainer', () => {
  let wrapper;

  const factory = (mrUpdates = {}, provide = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(MrWidgetPipelineContainer), {
      propsData: {
        mr: Object.assign({}, mockStore, mrUpdates),
      },
      provide: {
        ...provide,
      },
      localVue,
      sync: false,
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('merge train indicator', () => {
    it('should render the merge train indicator if the MR is open and is on the merge train', () => {
      factory({
        isOpen: true,
        autoMergeStrategy: MT_MERGE_STRATEGY,
      });

      expect(wrapper.find(MergeTrainPositionIndicator).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is closed', () => {
      factory({
        isOpen: false,
        autoMergeStrategy: MT_MERGE_STRATEGY,
      });

      expect(wrapper.find(MergeTrainPositionIndicator).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is not on the merge train', () => {
      factory({
        isOpen: true,
        autoMergeStrategy: MWPS_MERGE_STRATEGY,
      });

      expect(wrapper.find(MergeTrainPositionIndicator).exists()).toBe(false);
    });
  });

  describe('with anonymous visual review feedback feature flag enabled', () => {
    beforeEach(() => {
      factory(
        {
          visualReviewAppAvailable: true,
          appUrl: 'http://gitlab.example.com',
          iid: 1,
          sourceProjectId: 20,
          sourceProjectFullPath: 'source/project',
        },
        {
          glFeatures: {
            anonymousVisualReviewFeedback: true,
          },
        },
      );

      // the visual review app link component is lazy loaded
      // so we need to re-render the component
      return wrapper.vm.$nextTick();
    });

    it('renders the visual review app link', done => {
      // the visual review app link component is lazy loaded
      // so we need to re-render the component again, as once
      // apparently isn't enough.
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find(VisualReviewAppLink).exists()).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with anonymous visual review feedback feature flag disabled', () => {
    beforeEach(() => {
      factory(
        {
          visualReviewAppAvailable: true,
          appUrl: 'http://gitlab.example.com',
          iid: 1,
          sourceProjectId: 20,
          sourceProjectFullPath: 'source/project',
        },
        {
          glFeatures: {
            anonymousVisualReviewFeedback: false,
          },
        },
      );

      // the visual review app link component is lazy loaded
      // so we need to re-render the component
      return wrapper.vm.$nextTick();
    });

    it('does not render the visual review app link', done => {
      // the visual review app link component is lazy loaded
      // so we need to re-render the component again, as once
      // apparently isn't enough.
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find(VisualReviewAppLink).exists()).toEqual(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
