<script>
import { GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlLink,
    Icon,
  },
  props: {
    helpPagePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <article>
    <header>
      <h2 class="settings-title">
        {{ __('Configure Security and Compliance') }}
        <gl-link
          target="_blank"
          :href="helpPagePath"
          :aria-label="__('Security configuration help link')"
        >
          <icon name="question" />
        </gl-link>
      </h2>
    </header>
    <section class="alert alert-primary mt-3">
      Configuration status only applies to the default branch and is based on the latest pipeline
      scan.
    </section>
    <section class="mt-4">
      <div class="gl-responsive-table-row table-row-header text-2 px-2" role="row">
        <div class="table-section section-80">{{ __('Secure features') }}</div>
        <div class="table-section section-20">{{ __('Status') }}</div>
      </div>
      <div class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2">
        <div class="d-md-flex align-items-baseline">
          <div class="table-section section-80 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">Secure features</div>
            <div class="table-mobile-content">
              <div>Static Application Security Testing (SAST)</div>
              <div class="text-secondary">Analyze your source code for known vulnerabilities</div>
            </div>
          </div>
          <div class="table-section section-20 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">Status</div>
            <div class="table-mobile-content">
              Configured
            </div>
          </div>
        </div>
      </div>
    </section>
  </article>
</template>
