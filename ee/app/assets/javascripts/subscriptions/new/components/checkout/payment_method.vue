<script>
import _ from 'underscore';
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { mapState } from 'vuex';
import Step from './components/step.vue';
import Zuora from './components/zuora.vue';

export default {
  components: {
    GlSprintf,
    Step,
    Zuora,
  },
  computed: {
    ...mapState(['paymentMethodId', 'creditCardDetails']),
    isValid() {
      return !_.isEmpty(this.paymentMethodId);
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Payment method'),
    creditCardDetails: s__('Checkout|%{cardType} ending in %{lastFourDigits}'),
    expirationDate: s__('Checkout|Exp %{expirationMonth}/%{expirationYear}'),
  },
};
</script>
<template>
  <step step="paymentMethod" :title="$options.i18n.stepTitle" :is-valid="isValid">
    <template #body="props">
      <zuora :active="props.active" />
    </template>
    <template #summary>
      <div class="js-summary-line-1">
        <gl-sprintf :message="$options.i18n.creditCardDetails">
          <template #cardType>
            {{ creditCardDetails.cardType }}
          </template>
          <template #lastFourDigits>
            <strong>{{ creditCardDetails.lastFourDigits }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="js-summary-line-2">
        {{
          sprintf($options.i18n.expirationDate, {
            expirationMonth: creditCardDetails.expirationMonth,
            expirationYear: creditCardDetails.expirationYear,
          })
        }}
      </div>
    </template>
  </step>
</template>
