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
    features: {
      type: Array,
      required: true,
    }
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
      {{ __('Configuration status only applies to the default branch and is based on the latest pipeline scan.') }}
    </section>
    <section class="mt-4">
      <div class="gl-responsive-table-row table-row-header text-2 font-weight-bold px-2" role="row">
        <div class="table-section section-80">{{ __('Secure features') }}</div>
        <div class="table-section section-20">{{ __('Status') }}</div>
      </div>
      <div
        v-for="feature in features"
        :key="feature.name"
        class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2"
      >
        <div class="d-md-flex align-items-center">
          <div class="table-section section-80 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">{{ __('Feature') }}</div>
            <div class="table-mobile-content">
              <div class="d-flex align-items-center justify-content-end justify-content-md-start">
                <div class="text-2">
                  {{ feature.name }}
                </div>
                <gl-link
                  class="d-inline-flex ml-1"
                  target="_blank"
                  :href="feature.link"
                  aria-label="@TODO"
                  ><icon name="external-link"
                /></gl-link>
              </div>
              <div class="text-secondary">{{ feature.description }}</div>
            </div>
          </div>
          <div class="table-section section-20 section-wrap pr-md-3">
            <div role="rowheader" class="table-mobile-header">{{ __('Status') }}</div>
            <div class="table-mobile-content">
              {{ feature.configured ? 'Configured' : 'Not yet' }}
            </div>
          </div>
        </div>
      </div>
    </section>
  </article>
</template>
