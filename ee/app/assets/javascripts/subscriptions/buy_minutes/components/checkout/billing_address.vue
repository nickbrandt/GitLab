<script>
import { GlFormGroup, GlFormInput, GlFormSelect } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { STEPS } from 'ee/subscriptions/constants';
import UPDATE_STATE from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import COUNTRIES_QUERY from 'ee/subscriptions/graphql/queries/countries.query.graphql';
import STATE_QUERY from 'ee/subscriptions/graphql/queries/state.query.graphql';
import STATES_QUERY from 'ee/subscriptions/graphql/queries/states.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  components: {
    Step,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      country: null,
      address1: null,
      address2: null,
      city: null,
      state: null,
      zipCode: null,
      company: null,
    };
  },
  apollo: {
    state: {
      query: STATE_QUERY,
      manual: true,
      result({ data, loading }) {
        if (loading) {
          return;
        }

        const {customer} = data;
        this.country = customer.country;
        this.address1 = customer.address1;
        this.address2 = customer.address2;
        this.city = customer.city;
        this.state = customer.state;
        this.zipCode = customer.zipCode;
        this.company = customer.company;
      },
    },
    countries: {
      query: COUNTRIES_QUERY,
    },
    states: {
      query: STATES_QUERY,
      skip() { return !this.country; },
      variables() {
        return {
          countryId: this.country,
        };
      },
    },
  },
  computed: {
    countryModel: {
      get() {
        return this.country;
      },
      set(country) {
        this.updateState({ customer: { country } });
      },
    },
    streetAddressLine1Model: {
      get() {
        return this.address1;
      },
      set(address1) {
        this.updateState({ customer: { address1 } });
      },
    },
    streetAddressLine2Model: {
      get() {
        return this.address2;
      },
      set(address2) {
        this.updateState({ customer: { address2 } });
      },
    },
    cityModel: {
      get() {
        return this.city;
      },
      set(city) {
        this.updateState({ customer: { city } });
      },
    },
    countryStateModel: {
      get() {
        return this.state;
      },
      set(state) {
        this.updateState({ customer: { state } });
      },
    },
    zipCodeModel: {
      get() {
        return this.zipCode;
      },
      set(zipCode) {
        this.updateState({ customer: { zipCode } });
      },
    },
    isValid() {
      return (
        !isEmpty(this.country) &&
        !isEmpty(this.address1) &&
        !isEmpty(this.city) &&
        !isEmpty(this.zipCode)
      );
    },
    countryOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.countrySelectPrompt,
          id: null,
        },
        ...this.countries,
      ];
    },
    stateOptionsWithDefault() {
      return [
        {
          name: this.$options.i18n.stateSelectPrompt,
          id: null,
        },
        ...this.states,
      ];
    },
  },
  methods: {
   updateState(payload) {
      this.$apollo.mutate({
        mutation: UPDATE_STATE,
        variables: {
          input: payload,
        },
      }).catch((error) => {
        createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
      });
    }
  },
  i18n: {
    stepTitle: s__('Checkout|Billing address'),
    nextStepButtonText: s__('Checkout|Continue to payment'),
    countryLabel: s__('Checkout|Country'),
    countrySelectPrompt: s__('Checkout|Please select a country'),
    streetAddressLabel: s__('Checkout|Street address'),
    cityLabel: s__('Checkout|City'),
    stateLabel: s__('Checkout|State'),
    stateSelectPrompt: s__('Checkout|Please select a state'),
    zipCodeLabel: s__('Checkout|Zip code'),
  },
  stepId: STEPS[1].id,
};
</script>
<template>
  <step
    v-if="!$apollo.loading"
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    :next-step-button-text="$options.i18n.nextStepButtonText"
  >
    <template #body>
      <gl-form-group :label="$options.i18n.countryLabel" label-size="sm" class="mb-3">
        <gl-form-select
          v-model="countryModel"
          v-autofocusonshow
          :options="countryOptionsWithDefault"
          class="js-country"
          value-field="id"
          text-field="name"
          data-qa-selector="country"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.streetAddressLabel" label-size="sm" class="mb-3">
        <gl-form-input
          v-model="streetAddressLine1Model"
          type="text"
          data-qa-selector="street_address_1"
        />
        <gl-form-input
          v-model="streetAddressLine2Model"
          type="text"
          data-qa-selector="street_address_2"
        />
      </gl-form-group>
      <gl-form-group :label="$options.i18n.cityLabel" label-size="sm" class="mb-3">
        <gl-form-input v-model="cityModel" type="text" data-qa-selector="city" />
      </gl-form-group>
      <div class="combined d-flex">
        <gl-form-group :label="$options.i18n.stateLabel" label-size="sm" class="mr-3 w-50">
          <gl-form-select
            v-if="states"
            v-model="countryStateModel"
            :options="stateOptionsWithDefault"
            value-field="id"
            text-field="name"
            data-qa-selector="state"
          />
        </gl-form-group>
        <gl-form-group :label="$options.i18n.zipCodeLabel" label-size="sm" class="w-50">
          <gl-form-input v-model="zipCodeModel" type="text" data-qa-selector="zip_code" />
        </gl-form-group>
      </div>
    </template>
    <template #summary>
      <div class="js-summary-line-1">{{ address1 }}</div>
      <div class="js-summary-line-2">{{ address2 }}</div>
      <div class="js-summary-line-3">{{ city }}, {{ country }} {{ state }} {{ zipCode }}</div>
    </template>
  </step>
</template>
