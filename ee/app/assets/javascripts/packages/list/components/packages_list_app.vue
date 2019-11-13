<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import PackageList from './packages_list.vue';

export default {
  components: {
    GlEmptyState,
    PackageList,
  },
  props: {
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    groupId: {
      type: String,
      required: false,
      default: '',
    },
    canDestroyPackage: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyListIllustration: {
      type: String,
      required: true,
    },
    emptyListHelpUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    emptyListText() {
      return sprintf(
        s__(
          'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
        ),
        {
          noPackagesLinkStart: `<a href="${this.emptyListHelpUrl}" target="_blank">`,
          noPackagesLinkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>

<template>
  <package-list :can-destroy-package="canDestroyPackage">
    <template #empty-state>
      <gl-empty-state
        :title="s__('PackageRegistry|There are no packages yet')"
        :svg-path="emptyListIllustration"
      >
        <template #description>
          <p v-html="emptyListText"></p>
        </template>
      </gl-empty-state>
    </template>
  </package-list>
</template>
