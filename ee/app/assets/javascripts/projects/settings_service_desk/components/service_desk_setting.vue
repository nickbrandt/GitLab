<script>
import Toggle from '~/vue_shared/components/toggle_button.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskSetting',
  directives: {
    tooltip,
  },

  components: {
    ClipboardButton,
    Toggle,
  },

  props: {
    isEnabled: {
      type: Boolean,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    onCheckboxToggle(isChecked) {
      eventHub.$emit('serviceDeskEnabledCheckboxToggled', isChecked);
    },
  },
};
</script>

<template>
  <div>
    <toggle
      id="service-desk-checkbox"
      ref="service-desk-checkbox"
      :value="isEnabled"
      class="d-inline-block align-middle mr-1"
      @change="onCheckboxToggle"
    />
    <label class="font-weight-bold" for="service-desk-checkbox">
      {{ __('Activate Service Desk') }}
    </label>
    <div v-if="isEnabled" class="row mt-3">
      <div class="col-md-9 mb-0">
        <strong id="incoming-email-describer" class="d-block mb-1">
          {{ __('Forward external support email address to') }}
        </strong>
        <template v-if="incomingEmail">
          <div class="input-group">
            <input
              ref="service-desk-incoming-email"
              type="text"
              class="form-control incoming-email h-auto"
              :placeholder="__('Incoming email')"
              :aria-label="__('Incoming email')"
              aria-describedby="incoming-email-describer"
              :value="incomingEmail"
              disabled="true"
            />
            <div class="input-group-append">
              <clipboard-button
                :title="__('Copy')"
                :text="incomingEmail"
                css-class="btn qa-clipboard-button"
              />
            </div>
          </div>
        </template>
        <template v-else>
          <i class="fa fa-spinner fa-spin" aria-hidden="true"> </i>
          <span class="sr-only">{{ __('Fetching incoming email') }}</span>
        </template>
      </div>
    </div>
  </div>
</template>
