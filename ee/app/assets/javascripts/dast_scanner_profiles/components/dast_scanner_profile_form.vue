<script>
import * as Sentry from '@sentry/browser';
import { isEqual } from 'lodash';
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlModal,
  GlIcon,
  GlTooltipDirective,
  GlInputGroupText,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import { serializeFormObject, isEmptyValue } from '~/lib/utils/forms';
import dastScannerProfileCreateMutation from '../graphql/dast_scanner_profile_create.mutation.graphql';

const initField = (value, isRequired = false) => ({
  value,
  required: isRequired,
  state: null,
  feedback: null,
});

const SPIDER_TIMEOUT_MIN = 0;
const SPIDER_TIMEOUT_MAX = 2880;
const TARGET_TIMEOUT_MIN = 1;
const TARGET_TIMEOUT_MAX = 3600;

export default {
  name: 'DastScannerProfileForm',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlModal,
    GlIcon,
    GlInputGroupText,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    profilesLibraryPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const form = {
      profileName: initField('', true),
      spiderTimeout: initField('', true),
      targetTimeout: initField('', true),
    };

    return {
      form,
      initialFormValues: serializeFormObject(form),
      loading: false,
      showAlert: false,
    };
  },
  spiderTimeoutRange: {
    min: SPIDER_TIMEOUT_MIN,
    max: SPIDER_TIMEOUT_MAX,
  },
  targetTimeoutRange: {
    min: TARGET_TIMEOUT_MIN,
    max: TARGET_TIMEOUT_MAX,
  },
  computed: {
    formTouched() {
      return !isEqual(serializeFormObject(this.form), this.initialFormValues);
    },
    formHasErrors() {
      return Object.values(this.form).some(({ state }) => state === false);
    },
    requiredFieldEmpty() {
      return Object.values(this.form).some(
        ({ required, value }) => required && isEmptyValue(value),
      );
    },
    isSubmitDisabled() {
      return this.formHasErrors || this.requiredFieldEmpty;
    },
  },

  methods: {
    validateTimeout(timeoutObject, range) {
      const timeout = timeoutObject;

      const hasValue = timeout.value !== '';
      const isOutOfRange = timeout.value < range.min || timeout.value > range.max;

      if (hasValue && isOutOfRange) {
        timeout.state = false;
        timeout.feedback = s__('DastProfiles|Please enter a valid timeout value');
        return;
      }
      timeout.state = true;
      timeout.feedback = null;
    },
    validateSpiderTimeout() {
      this.validateTimeout(this.form.spiderTimeout, this.$options.spiderTimeoutRange);
    },
    validateTargetTimeout() {
      this.validateTimeout(this.form.targetTimeout, this.$options.targetTimeoutRange);
    },
    onSubmit() {
      this.loading = true;
      this.hideErrors();

      const variables = {
        projectFullPath: this.projectFullPath,
        ...serializeFormObject(this.form),
      };

      this.$apollo
        .mutate({
          mutation: dastScannerProfileCreateMutation,
          variables,
        })
        .then(({ data: { dastScannerProfileCreate: { errors = [] } } }) => {
          if (errors.length > 0) {
            this.showErrors(errors);
            this.loading = false;
          } else {
            redirectTo(this.profilesLibraryPath);
          }
        })
        .catch(e => {
          Sentry.captureException(e);
          this.showErrors();
          this.loading = false;
        });
    },
    onCancelClicked() {
      if (!this.formTouched) {
        this.discard();
      } else {
        this.$refs[this.$options.modalId].show();
      }
    },
    discard() {
      redirectTo(this.profilesLibraryPath);
    },
    showErrors(errors = []) {
      this.errors = errors;
      this.showAlert = true;
    },
    hideErrors() {
      this.errors = [];
      this.showAlert = false;
    },
  },
  modalId: 'deleteDastProfileModal',
  i18n: {
    modalTitle: s__('DastProfiles|Do you want to discard this scanner profile?'),
    modalOkTitle: __('Discard'),
    modalCancelTitle: __('Cancel'),
    spiderTimeoutTooltip: '',
    targetTimeoutTooltip: '',
  },
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <h2 class="gl-mb-6">
      {{ s__('DastProfiles|New scanner profile') }}
    </h2>

    <gl-alert v-if="showAlert" variant="danger" class="gl-mb-5" @dismiss="hideErrors">
      {{ s__('DastProfiles|Could not create the scanner profile. Please try again.') }}
      <ul v-if="errors.length" class="gl-mt-3 gl-mb-0">
        <li v-for="error in errors" :key="error" v-text="error"></li>
      </ul>
    </gl-alert>

    <gl-form-group :label="s__('DastProfiles|Profile name')">
      <gl-form-input
        v-model="form.profileName.value"
        class="mw-460"
        data-testid="profile-name-input"
        type="text"
      />
    </gl-form-group>

    <hr />

    <div class="row">
      <gl-form-group
        class="col-md-6"
        :state="form.spiderTimeout.state"
        :invalid-feedback="form.spiderTimeout.feedback"
      >
        <template #label>
          {{ s__('DastProfiles|Spider timeout') }}
          <gl-icon
            v-if="$options.i18n.spiderTimeoutTooltip"
            v-gl-tooltip.hover
            name="information-o"
            class="gl-vertical-align-text-bottom gl-text-gray-400 gl-ml-2"
            :title="$options.i18n.spiderTimeoutTooltip"
          />
        </template>
        <gl-form-input-group
          v-model.number="form.spiderTimeout.value"
          class="mw-460"
          data-testid="spider-timeout-input"
          type="number"
          :min="$options.spiderTimeoutRange.min"
          :max="$options.spiderTimeoutRange.max"
          @input="validateSpiderTimeout"
        >
          <template #append>
            <gl-input-group-text>{{ __('Minutes') }}</gl-input-group-text>
          </template>
        </gl-form-input-group>
        <div class="gl-text-gray-400 gl-my-2">
          {{ s__('DastProfiles|Minimum = 0 (no timeout enabled), Maximum = 2880 minutes') }}
        </div>
      </gl-form-group>

      <gl-form-group
        class="col-md-6"
        :state="form.targetTimeout.state"
        :invalid-feedback="form.targetTimeout.feedback"
      >
        <template #label>
          {{ s__('DastProfiles|Target timeout') }}
          <gl-icon
            v-if="$options.i18n.targetTimeoutTooltip"
            v-gl-tooltip.hover
            name="information-o"
            class="gl-vertical-align-text-bottom gl-text-gray-400 gl-ml-2"
            :title="$options.i18n.targetTimeoutTooltip"
          />
        </template>
        <gl-form-input-group
          v-model.number="form.targetTimeout.value"
          class="mw-460"
          data-testid="target-timeout-input"
          type="number"
          :min="$options.targetTimeoutRange.min"
          :max="$options.targetTimeoutRange.max"
          @input="validateTargetTimeout"
        >
          <template #append>
            <gl-input-group-text>{{ __('Seconds') }}</gl-input-group-text>
          </template>
        </gl-form-input-group>
        <div class="gl-text-gray-400 gl-my-2">
          {{ s__('DastProfiles|Minimum = 1 second, Maximum = 3600 seconds') }}
        </div>
      </gl-form-group>
    </div>

    <hr />

    <gl-button
      type="submit"
      variant="success"
      class="js-no-auto-disable"
      data-testid="dast-scanner-profile-form-submit-button"
      :disabled="isSubmitDisabled"
      :loading="loading"
    >
      {{ s__('DastProfiles|Save profile') }}
    </gl-button>
    <gl-button
      class="gl-ml-2"
      data-testid="dast-scanner-profile-form-cancel-button"
      @click="onCancelClicked"
    >
      {{ __('Cancel') }}
    </gl-button>

    <gl-modal
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="$options.i18n.modalTitle"
      :ok-title="$options.i18n.modalOkTitle"
      :cancel-title="$options.i18n.modalCancelTitle"
      ok-variant="danger"
      body-class="gl-display-none"
      data-testid="dast-scanner-profile-form-cancel-modal"
      @ok="discard()"
    />
  </gl-form>
</template>
