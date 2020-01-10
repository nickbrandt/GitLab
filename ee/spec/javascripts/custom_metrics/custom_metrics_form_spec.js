import { createLocalVue, shallowMount } from '@vue/test-utils';
import CustomMetricsForm from 'ee/custom_metrics/components/custom_metrics_form.vue';

const localVue = createLocalVue();

describe('CustomMetricsForm', () => {
  let wrapper;

  function mountComponent({
    metricPersisted = false,
    formData = {
      title: '',
      query: '',
      yLabel: '',
      unit: '',
      group: '',
      legend: '',
    },
  }) {
    wrapper = shallowMount(localVue.extend(CustomMetricsForm), {
      localVue,
      propsData: {
        customMetricsPath: '',
        editProjectServicePath: '',
        metricPersisted,
        validateQueryPath: '',
        formData,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('Computed', () => {
    it('Form button and title text indicate the custom metric is being edited', () => {
      mountComponent({ metricPersisted: true });

      expect(wrapper.vm.saveButtonText).toEqual('Save Changes');
      expect(wrapper.vm.titleText).toEqual('Edit metric');
    });

    it('Form button and title text indicate the custom metric is being created', () => {
      mountComponent({ metricPersisted: false });

      expect(wrapper.vm.saveButtonText).toEqual('Create metric');
      expect(wrapper.vm.titleText).toEqual('New metric');
    });
  });
});
