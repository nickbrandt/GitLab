<script>
import { GlLink, GlCard, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlLink,
    GlCard,
    GlFormCheckbox,
    GlSprintf,
    Icon,
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
    // TODO: make this required when the feature flag is removed
    suggestedSolutionsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    suggestedSolutionsEnabledInitial: {
      type: Boolean,
      required: false,
      default: true,
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
  },
  data() {
    return {
      suggestedSolutionsEnabled: this.suggestedSolutionsEnabledInitial,
      suggestedSolutionsLoading: false,
    };
  },
  computed: {
    headerContent() {
      const body = __('Configure Security %{wordBreakOpportunity}and Compliance');
      const wordBreakOpportunity = '<wbr />';

      return sprintf(body, { wordBreakOpportunity }, false);
    },
    callOutLink() {
      return this.autoDevopsEnabled ? this.autoDevopsHelpPagePath : this.latestPipelinePath;
    },
    calloutContent() {
      const bodyDefault = __(`The configuration status of the table below only applies to the default branch and
          is based on the %{linkStart}latest pipeline%{linkEnd}.
          Once you've configured a scan for the default branch, any subsequent feature branch you create will include the scan.`);

      const bodyAutoDevopsEnabled = __(
        'All security scans are enabled because %{linkStart}Auto DevOps%{linkEnd} is enabled on this project',
      );

      const body = this.autoDevopsEnabled ? bodyAutoDevopsEnabled : bodyDefault;

      const linkStart = `<a href="${this.callOutLink}" target="_blank" rel="noopener">`;
      const linkEnd = '</a>';

      return sprintf(body, { linkStart, linkEnd }, false);
    },
  },
  methods: {
    getFeatureDocumentationLinkLabel(featureName) {
      return sprintf(s__('SecurityConfiguration|Feature documentation for %{featureName}'), {
        featureName,
      });
    },
    toggleSuggestedSolutions(enabled) {
      this.suggestedSolutionsLoading = true;
      // Simulate API call for now
      setTimeout(() => {
        this.suggestedSolutionsEnabled = enabled;
        this.suggestedSolutionsLoading = false;
      }, 1000);
    },
  },
};
</script>

<template>
  <article>
    <header>
      <h2 class="h4 my-3">
        <span v-html="headerContent"></span>
        <gl-link
          target="_blank"
          :href="helpPagePath"
          :aria-label="__('Security configuration help link')"
        >
          <icon name="question" />
        </gl-link>
      </h2>
    </header>
    <section
      ref="callout"
      class="bs-callout bs-callout-info mb-3 m-md-1 text-secondary"
      v-html="calloutContent"
    ></section>
    <section ref="featuresTable" class="mt-0">
      <div
        class="gl-responsive-table-row table-row-header text-2 font-weight-bold px-2 gl-text-gray-900"
        role="row"
      >
        <div class="table-section section-80">
          {{ s__('SecurityConfiguration|Secure features') }}
        </div>
        <div class="table-section section-20">{{ s__('SecurityConfiguration|Status') }}</div>
      </div>
      <div
        v-for="feature in features"
        ref="featureRow"
        :key="feature.name"
        class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2"
      >
        <div class="d-md-flex align-items-center">
          <div class="table-section section-80 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">
              {{ s__('SecurityConfiguration|Feature') }}
            </div>
            <div class="table-mobile-content">
              <div class="d-flex align-items-center justify-content-end justify-content-md-start">
                <div class="text-2 gl-text-gray-900">
                  {{ feature.name }}
                </div>
              </div>
              <div class="text-secondary">
                {{ feature.description }}
                <gl-link
                  target="_blank"
                  :href="feature.link"
                  :aria-label="getFeatureDocumentationLinkLabel(feature.name)"
                  >{{ __('More information') }}</gl-link
                >
              </div>
            </div>
          </div>
          <div class="table-section section-20 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">
              {{ s__('SecurityConfiguration|Status') }}
            </div>
            <div ref="featureConfigStatus" class="table-mobile-content">
              {{
                feature.configured
                  ? s__('SecurityConfiguration|Configured')
                  : s__('SecurityConfiguration|Not yet configured')
              }}
            </div>
          </div>
        </div>
      </div>
    </section>
    <section v-if="glFeatures.suggestedSolution">
      <h2 class="h4 my-3">
        {{ __('Suggested Solutions') }}
        <gl-link
          target="_blank"
          :href="suggestedSolutionsHelpPagePath"
          :aria-label="__('Suggested solutions help link')"
        >
          <icon name="question" />
        </gl-link>
      </h2>
      <gl-card>
        <gl-form-checkbox
          :checked="suggestedSolutionsEnabled"
          :disabled="suggestedSolutionsLoading"
          @input="toggleSuggestedSolutions"
        >
          {{
            __('Automatically create merge requests for vulnerabilities that have fixes available.')
          }}
          <template #help>
            {{ __('Available for dependency and container scanning') }}
          </template>
        </gl-form-checkbox>
        <div class="gl-bg-blue-100 gl-p-3">
          <gl-sprintf
            v-if="suggestedSolutionsEnabled"
            :message="
              __(
                '%{securityBotLinkStart}GitLab Security Bot%{securityBotLinkEnd} is the author of the auto-created merge request. %{moreInfoLinkStart}More information%{moreInfoLinkEnd}.',
              )
            "
          >
            <template #securityBotLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
            <template #moreInfoLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
          <gl-sprintf
            v-else
            :message="
              __(
                'Once %{containerScanningLinkStart}Container Scanning%{containerScanningLinkEnd} and/or %{dependencyScanningLinkStart}Dependency Scanning%{dependencyScanningLinkEnd} are configured, settings will default to opt-in. %{securityBotLinkStart}GitLab Security Bot%{securityBotLinkEnd} will be the author of the auto-created merge request. %{moreInfoLinkStart}More information%{moreInfoLinkEnd}.',
              )
            "
          >
            <template #containerScanningLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
            <template #dependencyScanningLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
            <template #securityBotLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
            <template #moreInfoLink="{ content }">
              <gl-link href="#">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </div>
      </gl-card>
    </section>
  </article>
</template>
