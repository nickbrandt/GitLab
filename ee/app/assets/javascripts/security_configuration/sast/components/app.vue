<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    sastDocumentationPath: {
      type: String,
      required: true,
    },
  },
  helpText: s__(
    `SecurityConfiguration|Customize common SAST settings to suit your
    requirements. More advanced configuration options exist, which you can add
    to the configuration file this tool generates. It's important to note that
    if you make any configurations, they will be saved as overrides and will be
    %{strongStart}excluded from automatic updates%{strongEnd}.`,
  ),
};
</script>

<template>
  <article>
    <header class="my-3 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h2 class="h4">
        {{ __('SAST Configuration') }}
        <gl-link
          :href="sastDocumentationPath"
          class="vertical-align-middle"
          target="_blank"
          :aria-label="__('Help')"
        >
          <gl-icon name="question" />
        </gl-link>
      </h2>
      <p>
        <gl-sprintf :message="$options.helpText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>
    </header>
  </article>
</template>
