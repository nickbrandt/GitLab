<script>
import { GlLink } from '@gitlab/ui';
import { isRootRelative } from '~/lib/utils/url_utility';

export default {
  components: {
    GlLink,
  },
  inject: ['projectFullPath'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  computed: {
    commitPath() {
      const { projectFullPath, value } = this;
      // this ensures an absolute path, as `projectFullPath` can be relative in some cases (e.g.: pipeline security tab)
      const absoluteProjectPath = isRootRelative(projectFullPath)
        ? projectFullPath
        : `/${projectFullPath}`;

      return `${absoluteProjectPath}/-/commit/${value}`;
    },
  },
};
</script>

<template>
  <gl-link :href="commitPath">{{ value }}</gl-link>
</template>
