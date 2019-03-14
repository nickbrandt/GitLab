<script>
import Flash from '~/flash';
import { __ } from '~/locale';
import serviceDeskSetting from './service_desk_setting.vue';
import ServiceDeskStore from '../stores/service_desk_store';
import ServiceDeskService from '../services/service_desk_service';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskRoot',

  components: {
    serviceDeskSetting,
  },
  props: {
    initialIsEnabled: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    const store = new ServiceDeskStore({
      incomingEmail: this.incomingEmail,
    });

    return {
      store,
      state: store.state,
      isEnabled: this.initialIsEnabled,
    };
  },

  created() {
    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);

    this.service = new ServiceDeskService(this.endpoint);

    if (this.isEnabled && !this.store.state.incomingEmail) {
      this.fetchIncomingEmail();
    }
  },

  beforeDestroy() {
    eventHub.$off('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
  },

  methods: {
    fetchIncomingEmail() {
      if (this.flash) {
        this.flash.innerHTML = '';
      }

      this.service
        .fetchIncomingEmail()
        .then(res => res.json())
        .then(data => {
          const email = data.service_desk_address;
          if (!email) {
            throw new Error(__("Response didn't include `service_desk_address`"));
          }

          this.store.setIncomingEmail(email);
        })
        .catch(() => {
          this.flash = Flash(
            __('An error occurred while fetching the Service Desk address.'),
            'alert',
            this.$el,
          );
        });
    },

    onEnableToggled(isChecked) {
      this.isEnabled = isChecked;
      this.store.resetIncomingEmail();
      if (this.flash) {
        this.flash.remove();
        this.flash = undefined;
      }

      this.service
        .toggleServiceDesk(isChecked)
        .then(res => res.json())
        .then(data => {
          const email = data.service_desk_address;
          if (isChecked && !email) {
            throw new Error(__("Response didn't include `service_desk_address`"));
          }

          this.store.setIncomingEmail(email);
        })
        .catch(() => {
          const message = isChecked
            ? __('An error occurred while enabling Service Desk.')
            : __('An error occurred while disabling Service Desk.');

          this.flash = Flash(message, 'alert', this.$el);
        });
    },
  },
};
</script>

<template>
  <div>
    <div class="flash-container"></div>
    <service-desk-setting :is-enabled="isEnabled" :incoming-email="state.incomingEmail" />
  </div>
</template>
