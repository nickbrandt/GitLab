<script>
import { s__ } from '~/locale';
import { PROGRESS_STEPS } from '../constants';
import { mapState } from 'vuex';
import ProgressBar from './checkout/progress_bar.vue';
import SubscriptionDetails from './checkout/subscription_details.vue';
import BillingAddress from './checkout/billing_address.vue';
import PaymentMethod from './checkout/payment_method.vue';
import ConfirmOrder from './checkout/confirm_order.vue';

export default {
  components: { ProgressBar, SubscriptionDetails, BillingAddress, PaymentMethod, ConfirmOrder },
  data() {
    return {
      step: PROGRESS_STEPS.checkout,
    };
  },
  computed: {
    ...mapState(['isNewUser']),
  },
  i18n: {
    checkout: s__('Checkout|Checkout'),
  },
};
</script>
<template>
  <div class="checkout d-flex flex-column justify-content-between w-100">
    <div class="full-width">
      <progress-bar v-if="isNewUser" :step="step" />
      <div class="flash-container"></div>
      <h2 class="mt-4 mb-3 mb-lg-5">{{ $options.i18n.checkout }}</h2>
      <subscription-details />
      <billing-address />
      <payment-method />
    </div>
    <confirm-order />
  </div>
</template>
