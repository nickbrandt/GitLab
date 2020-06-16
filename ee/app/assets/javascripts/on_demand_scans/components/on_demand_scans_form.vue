<script>
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import { isAbsolute, redirectTo } from '~/lib/utils/url_utility';
import {
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import runDastScanMutation from '../graphql/run_dast_scan.mutation.graphql';
import { SCAN_TYPES } from '../constants';

const initField = value => ({
  value,
  state: null,
  feedback: null,
});

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    helpPagePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      form: {
        scanType: initField(SCAN_TYPES.PASSIVE),
        branch: initField(this.defaultBranch),
        targetUrl: initField(''),
      },
      loading: false,
    };
  },
  computed: {
    formData() {
      return {
        projectPath: this.projectPath,
        ...Object.fromEntries(Object.entries(this.form).map(([key, { value }]) => [key, value])),
      };
    },
    formHasErrors() {
      return Object.values(this.form).some(({ state }) => state === false);
    },
    someFieldEmpty() {
      return Object.values(this.form).some(({ value }) => !value);
    },
    isSubmitDisabled() {
      return this.formHasErrors || this.someFieldEmpty;
    },
  },
  methods: {
    validateTargetUrl() {
      let [state, feedback] = [true, null];
      const { value: targetUrl } = this.form.targetUrl;
      if (!isAbsolute(targetUrl)) {
        state = false;
        feedback = s__(
          'OnDemandScans|Please enter a valid URL format, ex: http://www.example.com/home',
        );
      }
      this.form.targetUrl = {
        ...this.form.targetUrl,
        state,
        feedback,
      };
    },
    onSubmit() {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: runDastScanMutation,
          variables: this.formData,
        })
        .then(({ data: { runDastScan: { pipelineUrl } } }) => {
          redirectTo(pipelineUrl);
        })
        .catch(e => {
          Sentry.captureException(e);
          createFlash(s__('OnDemandScans|Could not run the scan. Please try again.'));
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <header class="gl-mb-6">
      <h2>{{ s__('OnDemandScans|New on-demand DAST scan') }}</h2>
      <p>
        <gl-icon name="information-o" class="gl-vertical-align-text-bottom gl-text-gray-600" />
        <gl-sprintf
          :message="
            s__(
              'OnDemandScans|On-demand scans run outside the DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}',
            )
          "
        >
          <template #learnMoreLink="{ content }">
            <gl-link :href="helpPagePath">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-form-group>
      <template #label>
        {{ s__('OnDemandScans|Scan mode') }}
        <gl-icon
          v-gl-tooltip.hover
          name="information-o"
          class="gl-vertical-align-text-bottom gl-text-gray-600"
          :title="s__('OnDemandScans|Only a passive scan can be performed on demand.')"
        />
      </template>
      {{ s__('OnDemandScans|Passive DAST Scan') }}
    </gl-form-group>

    <gl-form-group>
      <template #label>
        {{ s__('OnDemandScans|Attached branch') }}
        <gl-icon
          v-gl-tooltip.hover
          name="information-o"
          class="gl-vertical-align-text-bottom gl-text-gray-600"
          :title="s__('OnDemandScans|Attached branch is where the scan job runs.')"
        />
      </template>
      {{ defaultBranch }}
    </gl-form-group>

    <gl-form-group :invalid-feedback="form.targetUrl.feedback">
      <template #label>
        {{ s__('OnDemandScans|Target URL') }}
        <gl-icon
          v-gl-tooltip.hover
          name="information-o"
          class="gl-vertical-align-text-bottom gl-text-gray-600"
          :title="s__('OnDemandScans|DAST will scan the target URL and any discovered sub URLs.')"
        />
      </template>
      <gl-form-input
        v-model="form.targetUrl.value"
        class="mw-460"
        data-testid="target-url-input"
        type="url"
        :state="form.targetUrl.state"
        @input="validateTargetUrl"
      />
    </gl-form-group>

    <div class="gl-mt-6 gl-pt-6">
      <gl-button
        type="submit"
        variant="success"
        class="js-no-auto-disable"
        :disabled="isSubmitDisabled"
        :loading="loading"
      >
        {{ s__('OnDemandScans|Run this scan') }}
      </gl-button>
      <gl-button @click="$emit('cancel')">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
