import Vue from 'vue';
import { __, sprintf } from '~/locale';
import CommaSeparatedListTokenSelector from '../components/comma_separated_list_token_selector.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '.js-allowed-email-domains',
    components: {
      CommaSeparatedListTokenSelector,
    },
    data() {
      const { hiddenInputId, labelId } = document.querySelector(this.$options.el).dataset;

      return { hiddenInputId, labelId };
    },
    render(createElement) {
      return createElement('comma-separated-list-token-selector', {
        props: {
          hiddenInputId: this.hiddenInputId,
          ariaLabelledby: this.labelId,
          placeholder: __('Enter domain'),
        },
        scopedSlots: {
          'user-defined-token-content': ({ inputText: value }) => {
            return sprintf(__('Add "%{value}" to allowlist'), { value });
          },
        },
      });
    },
  });
};
