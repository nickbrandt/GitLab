<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  components: { GlSprintf, GlLink },
  message: __(
    "No deployments detected. Use environments to control your software's continuous deployment. %{linkStart}Learn more about deployment jobs.%{linkEnd}",
  ),
  computed: {
    helpLink() {
      return helpPagePath('ci/environments/index.md');
    },
  },
};
</script>
<template>
  <span>
    <gl-sprintf :message="$options.message">
      <template #link="{ content }">
        <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
