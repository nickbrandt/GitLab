import { mount, createLocalVue } from '@vue/test-utils';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import { MT_MERGE_STRATEGY, MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import MergeTrainInfo from 'ee/vue_merge_request_widget/components/merge_train_info.vue';
import { mockStore } from 'spec/vue_mr_widget/mock_data';

describe('MrWidgetPipelineContainer', () => {
  let wrapper;

  const factory = (mrUpdates = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(MrWidgetPipelineContainer), {
      propsData: {
        mr: Object.assign({}, mockStore, mrUpdates),
      },
      localVue,
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

      expect(wrapper.find(MergeTrainInfo).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is closed', () => {
      factory({
        isOpen: false,
        autoMergeStrategy: MT_MERGE_STRATEGY,
      });

      expect(wrapper.find(MergeTrainInfo).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is not on the merge train', () => {
      factory({
        isOpen: true,
        autoMergeStrategy: MWPS_MERGE_STRATEGY,
      });

      expect(wrapper.find(MergeTrainInfo).exists()).toBe(false);
    });
  });
});
