<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';

import { helpPagePath } from '~/helpers/help_page_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/wrapper';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

export default {
  components: {
    ColorPicker,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  props: {
    groupEditPath: {
      type: String,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      complianceFramework: {},
      error: '',
      isLoaded: false,
      validColor: null,
    };
  },
  computed: {
    validTitle() {
      if (Object.keys(this.complianceFramework).includes('name')) {
        return this.complianceFramework.name !== '';
      }

      return true;
    },
    disableSubmitBtn() {
      return (!this.complianceFramework?.title?.length && !this.validTitle) || !this.validColor;
    },
    scopedLabelsHelpPath() {
      return helpPagePath('user/project/labels.md', { anchor: 'scoped-labels' });
    },
    isLoading() {
      return !this.isLoaded;
    },
  },
  async mounted() {
    this.isLoaded = false;

    try {
      this.complianceFramework = await this.service.getComplianceFramework();
    } catch (e) {
      this.setError(e, this.$options.i18n.fetchError);
    }

    this.isLoaded = true;
  },
  methods: {
    setError(error, userFriendlyText) {
      this.error = userFriendlyText;
      Sentry.captureException(error);
    },
    async onSubmit(event) {
      event.preventDefault();

      this.isLoaded = false;

      try {
        await this.service.putComplianceFramework(this.complianceFramework);
        visitUrl(this.groupEditPath);
      } catch (e) {
        this.setError(e, e.toString());
      }

      this.isLoaded = true;
    },
    colorValidation(valid) {
      this.validColor = valid;
    },
  },
  i18n: {
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page',
    ),
    titleInputLabel: s__('ComplianceFrameworks|Title'),
    titleInputDescription: s__(
      'ComplianceFrameworks|Use %{codeStart}::%{codeEnd} to create a %{linkStart}scoped set%{linkEnd} (eg. %{codeStart}SOX::AWS%{codeEnd})',
    ),
    titleInputInvalid: s__('ComplianceFrameworks|A title is required'),
    descriptionInputLabel: s__('ComplianceFrameworks|Description'),
    colorInputLabel: s__('ComplianceFrameworks|Background color'),
    submitBtnText: s__('ComplianceFrameworks|Save changes'),
    cancelBtnText: s__('ComplianceFrameworks|Cancel'),
  },
};
</script>
<template>
  <div class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
    <gl-alert v-if="error" class="gl-mt-5" variant="danger" :dismissible="false">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />

    <gl-form v-if="!isLoading" @submit="onSubmit">
      <gl-form-group
        :label="$options.i18n.titleInputLabel"
        :invalid-feedback="$options.i18n.titleInputInvalid"
        :state="validTitle"
        data-testid="name-input-group"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.titleInputDescription">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>

            <template #link="{ content }">
              <gl-link :href="scopedLabelsHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>

        <gl-form-input v-model="complianceFramework.name" data-testid="name-input" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.descriptionInputLabel">
        <gl-form-input v-model="complianceFramework.description" data-testid="description-input" />
      </gl-form-group>

      <color-picker
        v-model="complianceFramework.color"
        :label="$options.i18n.colorInputLabel"
        :set-color="complianceFramework.color"
        @validation="colorValidation"
      />

      <div
        class="gl-display-flex gl-justify-content-space-between gl-pt-5 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
      >
        <gl-button
          type="submit"
          variant="success"
          data-testid="submit-btn"
          :disabled="disableSubmitBtn"
          >{{ $options.i18n.submitBtnText }}</gl-button
        >
        <gl-button :href="groupEditPath" data-testid="cancel-btn">{{
          $options.i18n.cancelBtnText
        }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
