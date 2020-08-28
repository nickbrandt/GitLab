<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlFormRadioGroup,
  GlIcon,
  GlInputGroupText,
  GlLoadingIcon,
} from '@gitlab/ui';
import download from '~/lib/utils/downloader';
import { DAST_SITE_VALIDATION_METHOD_TEXT_FILE, DAST_SITE_VALIDATION_METHODS } from '../constants';

export default {
  name: 'DastSiteValidation',
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormRadioGroup,
    GlIcon,
    GlInputGroupText,
    GlLoadingIcon,
  },
  props: {
    targetUrl: {
      type: String,
      required: true,
    },
    token: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isValidating: false,
      hasValidationError: false,
      validationMethod: DAST_SITE_VALIDATION_METHOD_TEXT_FILE,
    };
  },
  computed: {
    isTextFileValidation() {
      return this.validationMethod === DAST_SITE_VALIDATION_METHOD_TEXT_FILE;
    },
    textFileName() {
      return `GitLab-DAST-Site-Validation-${this.token}.txt`;
    },
    locationStepLabel() {
      return DAST_SITE_VALIDATION_METHODS[this.validationMethod].i18n.locationStepLabel;
    },
  },
  watch: {
    targetUrl() {
      this.hasValidationError = false;
    },
  },
  methods: {
    downloadTextFile() {
      download({ fileName: this.textFileName, fileData: btoa(this.token) });
    },
    async validate() {
      // TODO: Trigger the dastSiteValidationCreate GraphQL mutation.
      // See https://gitlab.com/gitlab-org/gitlab/-/issues/238578
      this.hasValidationError = false;
      this.isValidating = true;
      try {
        await new Promise(resolve => {
          setTimeout(resolve, 1000);
        });
        this.isValidating = false;
        this.$emit('success');
      } catch (_) {
        this.hasValidationError = true;
        this.isValidating = false;
      }
    },
  },
  validationMethodOptions: Object.values(DAST_SITE_VALIDATION_METHODS),
};
</script>

<template>
  <gl-card class="gl-bg-gray-10">
    <gl-alert variant="warning" :dismissible="false" class="gl-mb-3">
      {{ s__('DastProfiles|Site is not validated yet, please follow the steps.') }}
    </gl-alert>
    <gl-form-group :label="s__('DastProfiles|Step 1 - Choose site validation method')">
      <gl-form-radio-group v-model="validationMethod" :options="$options.validationMethodOptions" />
    </gl-form-group>
    <gl-form-group
      v-if="isTextFileValidation"
      :label="s__('DastProfiles|Step 2 - Add following text to the target site')"
    >
      <gl-button
        variant="info"
        category="secondary"
        size="small"
        icon="download"
        data-testid="download-dast-text-file-validation-button"
        :aria-label="s__('DastProfiles|Download validation text file')"
        @click="downloadTextFile()"
      >
        {{ textFileName }}
      </gl-button>
    </gl-form-group>
    <gl-form-group :label="locationStepLabel" class="mw-460">
      <gl-form-input-group>
        <template #prepend>
          <gl-input-group-text>{{ targetUrl }}</gl-input-group-text>
        </template>
        <gl-form-input class="gl-bg-white!" />
      </gl-form-input-group>
    </gl-form-group>

    <hr />

    <gl-button
      variant="success"
      category="secondary"
      data-testid="validate-dast-site-button"
      :disabled="isValidating"
      @click="validate"
    >
      {{ s__('DastProfiles|Validate') }}
    </gl-button>
    <span
      class="gl-ml-3"
      :class="{ 'gl-text-orange-600': isValidating, 'gl-text-red-500': hasValidationError }"
    >
      <template v-if="isValidating">
        <gl-loading-icon inline /> {{ s__('DastProfiles|Validating...') }}
      </template>
      <template v-else-if="hasValidationError">
        <gl-icon name="status_failed" />
        {{
          s__(
            'DastProfiles|Validation failed, please make sure that you follow the steps above with the choosen method.',
          )
        }}
      </template>
    </span>
  </gl-card>
</template>
