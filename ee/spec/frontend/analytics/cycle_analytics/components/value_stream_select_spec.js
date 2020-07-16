import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import ValueStreamSelect from 'ee/analytics/cycle_analytics/components/value_stream_select.vue';

describe('ValueStreamSelect', () => {
  let wrapper = null;

  const createComponent = () => shallowMount(ValueStreamSelect, {});
  const findModal = () => wrapper.find(GlModal);
  const submitButtonDisabledState = () => findModal().props('actionPrimary').attributes[1].disabled;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Create value stream form', () => {
    it('submit button is disabled', () => {
      expect(submitButtonDisabledState()).toBe(true);
    });

    describe('with valid fields', () => {
      beforeEach(async () => {
        wrapper = createComponent();
        await wrapper.setData({ name: 'Cool stream' });
      });

      it('submit button is enabled', () => {
        expect(submitButtonDisabledState()).toBe(false);
      });

      it('emits the "create" event when submitted', () => {
        findModal().vm.$emit('primary');
        expect(wrapper.emitted().create[0]).toEqual([{ name: 'Cool stream' }]);
      });
    });
  });
});
