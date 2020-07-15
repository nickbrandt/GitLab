import Vue from 'vue';
import { __, sprintf } from '~/locale';
import CommaSeparatedListTokenSelector from '../components/comma_separated_list_token_selector.vue';

export default (el, placeholder, qaSelector) => {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      CommaSeparatedListTokenSelector,
    },
    data() {
      const {
        hiddenInputId,
        labelId,
        regexValidator,
        disallowedValues,
        errorMessage,
        disallowedValueErrorMessage,
      } = document.querySelector(this.$options.el).dataset;

      return {
        hiddenInputId,
        labelId,
        regexValidator,
        errorMessage,
        disallowedValueErrorMessage,
        ...(regexValidator ? { regexValidator: new RegExp(regexValidator) } : {}),
        ...(disallowedValues ? { disallowedValues: JSON.parse(disallowedValues) } : {}),
      };
    },
    render(createElement) {
      return createElement('comma-separated-list-token-selector', {
        attrs: {
          'data-qa-selector': qaSelector,
        },
        props: {
          hiddenInputId: this.hiddenInputId,
          ariaLabelledby: this.labelId,
          regexValidator: this.regexValidator,
          disallowedValues: this.disallowedValues,
          errorMessage: this.errorMessage,
          disallowedValueErrorMessage: this.disallowedValueErrorMessage,
          placeholder,
        },
        scopedSlots: {
          'user-defined-token-content': ({ inputText: value }) => {
            return sprintf(__('Add "%{value}"'), { value });
          },
        },
      });
    },
  });
};
