<script>
import { GlLink } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlLink,
    Icon,
  },
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
    pipelinesHelpPagePath: {
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
  },
  computed: {
    headerContent() {
      const body = __('Configure Security %{wordBreakOpportunity}and Compliance');
      const wordBreakOpportunity = '<wbr />';

      return sprintf(body, { wordBreakOpportunity }, false);
    },
    callOutLink() {
      if (this.autoDevopsEnabled) {
        return this.autoDevopsHelpPagePath;
      }

      if (this.latestPipelinePath) {
        return this.latestPipelinePath;
      }

      return this.pipelinesHelpPagePath;
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
      <div class="gl-responsive-table-row table-row-header text-2 font-weight-bold px-2" role="row">
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
                <div class="text-2">
                  {{ feature.name }}
                </div>
                <gl-link
                  class="d-inline-flex ml-1"
                  target="_blank"
                  :href="feature.link"
                  :aria-label="s__('SecurityConfiguration|Feature documentation')"
                  ><icon name="external-link"
                /></gl-link>
              </div>
              <div class="text-secondary">
                {{ feature.description }}
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
  </article>
</template>
