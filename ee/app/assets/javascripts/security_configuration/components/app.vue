<script>
import { GlAlert, GlLink, GlSprintf, GlTable } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AutoFixSettings from './auto_fix_settings.vue';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
    GlTable,
    AutoFixSettings,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    autoDevopsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    autoDevopsHelpPagePath: {
      type: String,
      required: true,
    },
    latestPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    features: {
      type: Array,
      required: true,
    },
    autoFixSettingsProps: {
      type: Object,
      required: true,
    },
    gitlabCiPresent: {
      type: Boolean,
      required: false,
      default: false,
    },
    autoDevopsPath: {
      type: String,
      required: false,
      default: '',
    },
    canEnableAutoDevops: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    devopsMessage() {
      return this.autoDevopsEnabled
        ? __(
            'All security scans are enabled because %{linkStart}Auto DevOps%{linkEnd} is enabled on this project',
          )
        : __(
            `The status of the table below only applies to the default branch and is based on the %{linkStart}latest pipeline%{linkEnd}. Once you've enabled a scan for the default branch, any subsequent feature branch you create will include the scan.`,
          );
    },
    devopsUrl() {
      return this.autoDevopsEnabled ? this.autoDevopsHelpPagePath : this.latestPipelinePath;
    },
    fields() {
      return [
        {
          key: 'feature',
          label: s__('SecurityConfiguration|Security Control'),
          thClass: 'gl-text-gray-900 bg-transparent border-bottom',
        },
        {
          key: 'configured',
          label: s__('SecurityConfiguration|Status'),
          thClass: 'gl-text-gray-900 bg-transparent border-bottom',
          formatter: this.getStatusText,
        },
      ];
    },
    shouldShowAutoDevopsAlert() {
      return Boolean(
        this.glFeatures.sastConfigurationByClick &&
          !this.autoDevopsEnabled &&
          !this.gitlabCiPresent &&
          this.canEnableAutoDevops,
      );
    },
  },
  methods: {
    getStatusText(value) {
      return value
        ? s__('SecurityConfiguration|Enabled')
        : s__('SecurityConfiguration|Not yet enabled');
    },
    getFeatureDocumentationLinkLabel(featureName) {
      return sprintf(s__('SecurityConfiguration|Feature documentation for %{featureName}'), {
        featureName,
      });
    },
  },
  autoDevopsAlertMessage: s__(`
    SecurityConfiguration|You can quickly enable all security scanning tools by
    enabling %{linkStart}Auto DevOps%{linkEnd}.`),
};
</script>

<template>
  <article>
    <header>
      <h4 class="my-3">{{ __('Security Configuration') }}</h4>
      <h5 class="gl-font-lg mt-5">{{ s__('SecurityConfiguration|Testing & Compliance') }}</h5>
      <p>
        <gl-sprintf :message="devopsMessage">
          <template #link="{ content }">
            <gl-link ref="pipelinesLink" :href="devopsUrl" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-alert
      v-if="shouldShowAutoDevopsAlert"
      :title="__('Auto DevOps')"
      :primary-button-text="__('Enable Auto DevOps')"
      :primary-button-link="autoDevopsPath"
      :dismissible="false"
      class="gl-mb-5"
    >
      <gl-sprintf :message="$options.autoDevopsAlertMessage">
        <template #link="{ content }">
          <gl-link :href="autoDevopsHelpPagePath" v-text="content" />
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-table ref="securityControlTable" :items="features" :fields="fields" stacked="md">
      <template #cell(feature)="{ item }">
        <div class="gl-text-gray-900">{{ item.name }}</div>
        <div>
          {{ item.description }}
          <gl-link
            target="_blank"
            :href="item.link"
            :aria-label="getFeatureDocumentationLinkLabel(item.name)"
          >
            {{ __('More information') }}
          </gl-link>
        </div>
      </template>
    </gl-table>
    <auto-fix-settings v-if="glFeatures.securityAutoFix" v-bind="autoFixSettingsProps" />
  </article>
</template>
