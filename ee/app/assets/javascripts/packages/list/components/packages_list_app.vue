<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import PackageList from './packages_list.vue';

export default {
  components: {
    GlEmptyState,
    GlLoadingIcon,
    PackageList,
  },
  computed: {
    ...mapState({
      isLoading: 'isLoading',
      resourceId: state => state.config.resourceId,
      emptyListIllustration: state => state.config.emptyListIllustration,
      emptyListHelpUrl: state => state.config.emptyListHelpUrl,
    }),
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
  mounted() {
    this.requestPackagesList();
  },
  methods: {
    ...mapActions(['requestPackagesList', 'requestDeletePackage']),
    onPageChanged(page) {
      return this.requestPackagesList({ page });
    },
    onPackageDeleteRequest(packageId) {
      return this.requestDeletePackage({ projectId: this.resourceId, packageId });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" />
  <package-list v-else @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
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
