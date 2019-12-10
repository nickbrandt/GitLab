<script>
import _ from 'underscore';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlFormGroup, GlFormSelect, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import Step from './components/step.vue';

export default {
  components: {
    GlFormGroup,
    GlFormSelect,
    GlFormInput,
    GlSprintf,
    GlLink,
    Step,
  },
  directives: {
    autofocusonshow,
  },
  computed: {
    ...mapState([
      'availablePlans',
      'selectedPlan',
      'isSetupForCompany',
      'organizationName',
      'numberOfUsers',
    ]),
    ...mapGetters(['selectedPlanText']),
    selectedPlanModel: {
      get() {
        return this.selectedPlan;
      },
      set(selectedPlan) {
        this.updateSelectedPlan(selectedPlan);
      },
    },
    numberOfUsersModel: {
      get() {
        return this.numberOfUsers;
      },
      set(number) {
        this.updateNumberOfUsers(number);
      },
    },
    organizationNameModel: {
      get() {
        return this.organizationName;
      },
      set(organizationName) {
        this.updateOrganizationName(organizationName);
      },
    },
    selectedPlanTextLine() {
      return sprintf(this.$options.i18n.selectedPlan, { selectedPlanText: this.selectedPlanText });
    },
    isValid() {
      if (this.isSetupForCompany) {
        return (
          !_.isEmpty(this.selectedPlan) &&
          !_.isEmpty(this.organizationName) &&
          this.numberOfUsers > 0
        );
      }
      return !_.isEmpty(this.selectedPlan) && this.numberOfUsers === 1;
    },
  },
  methods: {
    ...mapActions([
      'updateSelectedPlan',
      'toggleIsSetupForCompany',
      'updateNumberOfUsers',
      'updateOrganizationName',
    ]),
  },
  i18n: {
    stepTitle: s__('Checkout|Subscription details'),
    nextStepButtonText: s__('Checkout|Continue to billing'),
    selectedPlanLabel: s__('Checkout|GitLab plan'),
    organizationNameLabel: s__('Checkout|Name of company or organization using GitLab'),
    numberOfUsersLabel: s__('Checkout|Number of users'),
    needMoreUsersLink: s__('Checkout|Need more users? Purchase GitLab for your %{company}.'),
    companyOrTeam: s__('Checkout|company or team'),
    selectedPlan: s__('Checkout|%{selectedPlanText} plan'),
    group: s__('Checkout|Group'),
    users: s__('Checkout|Users'),
  },
};
</script>
<template>
  <step
    step="subscriptionDetails"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    :next-step-button-text="$options.i18n.nextStepButtonText"
  >
    <template #body>
      <gl-form-group
        :label="$options.i18n.selectedPlanLabel"
        label-size="sm"
        label-for="selectedPlan"
        class="append-bottom-default"
      >
        <gl-form-select
          id="selectedPlan"
          v-model="selectedPlanModel"
          v-autofocusonshow
          :options="availablePlans"
        />
      </gl-form-group>
      <gl-form-group
        v-if="isSetupForCompany"
        :label="$options.i18n.organizationNameLabel"
        label-size="sm"
        label-for="organizationName"
        class="append-bottom-default"
      >
        <gl-form-input id="organizationName" v-model="organizationNameModel" type="text" />
      </gl-form-group>
      <div class="combined d-flex">
        <gl-form-group
          :label="$options.i18n.numberOfUsersLabel"
          label-size="sm"
          label-for="numberOfUsers"
          class="number"
        >
          <gl-form-input
            id="numberOfUsers"
            v-model.number="numberOfUsersModel"
            type="number"
            min="0"
            :disabled="!isSetupForCompany"
          />
        </gl-form-group>
        <gl-form-group
          v-if="!isSetupForCompany"
          class="label prepend-left-default align-self-end company-link"
        >
          <gl-sprintf :message="$options.i18n.needMoreUsersLink">
            <template #company>
              <gl-link @click="toggleIsSetupForCompany">{{ $options.i18n.companyOrTeam }}</gl-link>
            </template>
          </gl-sprintf>
        </gl-form-group>
      </div>
    </template>
    <template #summary>
      <strong class="js-summary-line-1">
        {{ selectedPlanTextLine }}
      </strong>
      <div v-if="isSetupForCompany" class="js-summary-line-2">
        {{ $options.i18n.group }}: {{ organizationName }}
      </div>
      <div class="js-summary-line-3">{{ $options.i18n.users }}: {{ numberOfUsers }}</div>
    </template>
  </step>
</template>
