<script>
import Ide from '~/ide/components/ide.vue';
import EERightPane from './panes/right.vue';

export default {
  // name: 'EEIde' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/25
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'EEIde',
  components: {
    Ide,
  },
  EERightPane,
};
</script>

<template>
  <ide :right-pane-component="$options.EERightPane" />
</template>
