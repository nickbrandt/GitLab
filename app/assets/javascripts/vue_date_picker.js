import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import VueDatePicker from '~/vue_shared/components/date_picker.vue';

const mountVueDatePicker = el => {
  const props = {
    ...el.dataset,
    disabled: parseBoolean(el.dataset.disabled),
  };

  return new Vue({
    el,
    render(h) {
      return h(VueDatePicker, { props });
    },
  });
};

export default () => [...document.querySelectorAll('.js-vue-date-picker')].map(mountVueDatePicker);
