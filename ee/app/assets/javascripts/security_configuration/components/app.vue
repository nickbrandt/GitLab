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
          :href="helpPagePath"
          target="_blank"
          :aria-label="__('Security configuration help link')"
        >
          <icon name="question" />
        </gl-link>
      </h2>
    </header>
    <section class="alert alert-primary mt-3">
      Configuration status only applies to the default branch and is based on the latest pipeline scan.
    </section>
    <section class="mt-4">
      <h3 class="h5">{{ __('Secure features') }}</h3>
      <dl>
        <div>
          <div>
            <dt>Static Application Security Testing (SAST)</dt>
            <dd>Analyze your source code for known vulnerabilities</dd>
          </div>
          <dd>Configured</dd>
        </div>
      </dl>
    </section>
  </article>
</template>
