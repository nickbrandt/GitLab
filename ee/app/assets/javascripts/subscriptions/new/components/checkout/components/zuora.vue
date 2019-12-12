<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { ZUORA_SCRIPT_URL } from 'ee/subscriptions/new/constants';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      overrideParams: {
        style: 'inline',
        submitEnabled: 'true',
        retainValues: 'true',
      },
    };
  },
  computed: {
    ...mapState(['paymentFormParams', 'paymentMethodId', 'creditCardDetails']),
  },
  watch: {
    // The Zuora script has loaded and the parameters for rendering the iframe have been fetched.
    paymentFormParams() {
      this.renderZuoraIframe();
    },
    // The Zuora form has been submitted successfully and credit card details are being fetched.
    paymentMethodId() {
      this.toggleLoading();
    },
    // The credit card details have been fetched.
    creditCardDetails() {
      this.toggleLoading();
    },
  },
  mounted() {
    this.loadZuoraScript();
  },
  methods: {
    ...mapActions(['fetchPaymentFormParams', 'paymentFormSubmitted']),
    loadZuoraScript() {
      if (typeof window.Z === 'undefined') {
        const zuoraScript = document.createElement('script');
        zuoraScript.type = 'text/javascript';
        zuoraScript.async = true;
        zuoraScript.onload = this.fetchPaymentFormParams;
        zuoraScript.src = ZUORA_SCRIPT_URL;
        document.head.appendChild(zuoraScript);
      } else {
        this.fetchPaymentFormParams();
      }
    },
    renderZuoraIframe() {
      const params = { ...this.paymentFormParams, ...this.overrideParams };
      window.Z.runAfterRender(this.toggleLoading);
      window.Z.render(params, {}, this.paymentFormSubmitted);
    },
    toggleLoading() {
      this.loading = !this.loading;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="loading" size="lg" />
    <div v-show="active && !loading" id="zuora_payment"></div>
  </div>
</template>
