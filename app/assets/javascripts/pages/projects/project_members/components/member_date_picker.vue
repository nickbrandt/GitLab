<script>
import $ from 'jquery';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import { GlDatepicker } from '@gitlab/ui';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import Flash from '~/flash';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlDatepicker,
  },
  csrf,
  props: {
    elId: {
      type: String,
      required: false,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    label: {
      type: String,
      required: false,
      default: __('Date Picker'),
    },
    value: {
      type: Date,
      required: true,
      default: null,
    },
    name: {
      type: String,
      required: false,
      default: 'data',
    },
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedDate: this.value,
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
  },
  methods: {
    submitForm() {
      const url = this.$el.closest('.js-edit-member-form').getAttribute('action');
      const memberInfoEl = document.querySelector(`#${this.elId} .list-item-name`);
      const memberElId = this.elId;
      const data = { expires_at: this.selectedDate };

      return axios
        .patch(url, data)
        .then(function(response) {
          const htmlData = document.createElement('div');
          htmlData.innerHTML = response.data;

          const updateMemberInfoEl = htmlData.querySelector('.list-item-name');
          memberInfoEl.innerHTML = updateMemberInfoEl.innerHTML;

          localTimeAgo($('.js-timeago'), $(`#${memberElId}`));
        })
        .catch(() => {
          Flash(__('Failed to update the expiration date, please try again.'));
        });
    },
  },
};
</script>

<template>
  <gl-datepicker v-model="selectedDate" :min-date="new Date()" @input="submitForm">
    <input
      :id="id"
      :disabled="disabled"
      class="gl-datepicker-input form-control"
      :name="name"
      type="text"
      :aria-label="label"
      :placeholder="label"
      :data-el-id="elId"
    />
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token"/>
  </gl-datepicker>
</template>
