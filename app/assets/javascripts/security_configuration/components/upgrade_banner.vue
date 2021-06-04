<script>
import { GlBanner, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBanner,
    GlSprintf,
  },
  inject: ['upgradePath'],
  i18n: {
    title: s__('SecurityConfiguration|Secure your project with Ultimate'),
    listItems: [
      s__(
        'SecurityConfiguration|Check your application %{strongStart}before%{strongEnd} deployment for security vulnerabilities including unauthorized access, data leaks, denial of service attacks.',
      ),
      s__('SecurityConfiguration|Manage and report on vulnerabilities detected.'),
      s__(
        'SecurityConfiguration|Implement controls to prevent known vulnerabilities being added to your application.',
      ),
    ],
    buttonText: s__('SecurityConfiguration|Upgrade or start a free trial'),
  },
};
</script>

<template>
  <gl-banner
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="upgradePath"
    v-on="$listeners"
  >
    <ul>
      <li v-for="listItem in $options.i18n.listItems" :key="listItem">
        <gl-sprintf :message="listItem">
          <template #strong="{ content }"
            ><strong>{{ content }}</strong></template
          >
        </gl-sprintf>
      </li>
    </ul>
  </gl-banner>
</template>
