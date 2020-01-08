import { shallowMount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import MergeTrainPositionIndicator from 'ee/vue_merge_request_widget/components/merge_train_position_indicator.vue';

describe('MergeTrainPositionIndicator', () => {
  let wrapper;
  let vm;

  const factory = propsData => {
    wrapper = shallowMount(MergeTrainPositionIndicator, {
      propsData,
      sync: false,
    });

    ({ vm } = wrapper);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('message', () => {
      it('should return the message with the correct position (i.e., index + 1)', () => {
        factory({ mergeTrainIndex: 3 });

        expect(vm.message).toBe('In the merge train at position 4');
      });
    });

    describe('template', () => {
      it('should render the correct message', () => {
        factory({ mergeTrainIndex: 3 });

        expect(trimText(wrapper.text())).toBe('In the merge train at position 4');
      });
    });
  });
});
