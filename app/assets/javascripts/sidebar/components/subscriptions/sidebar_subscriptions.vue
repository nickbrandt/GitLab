<script>
import Store from '../../stores/sidebar_store';
import Flash from '../../../flash';
import { __ } from '../../../locale';
import subscriptions from './subscriptions.vue';

export default {
  components: {
    subscriptions,
  },
  props: {
    mediator: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      store: new Store(),
    };
  },
  methods: {
    onToggleSubscription() {
      this.mediator.toggleSubscription().catch(() => {
        Flash(__('Error occurred when toggling the notification subscription'));
      });
    },
  },
};
</script>

<template>
  <div class="block subscriptions">
    <subscriptions
      :loading="store.isFetching.subscriptions"
      :project_emails_disabled="store.project_emails_disabled"
      :subscribe_disabled_description="store.subscribe_disabled_description"
      :subscribed="store.subscribed"
      @toggleSubscription="onToggleSubscription"
    />
  </div>
</template>
