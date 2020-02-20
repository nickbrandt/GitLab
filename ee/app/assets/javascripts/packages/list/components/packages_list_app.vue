<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import PackageList from './packages_list.vue';

export default {
  components: {
    GlEmptyState,
    PackageList,
  },
  computed: {
    ...mapState({
      resourceId: state => state.config.resourceId,
      emptyListIllustration: state => state.config.emptyListIllustration,
      emptyListHelpUrl: state => state.config.emptyListHelpUrl,
      totalItems: state => state.pagination.total,
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
    onPackageDeleteRequest(item) {
      return this.requestDeletePackage(item);
    },
  },
};
</script>

<template>
  <package-list
    @page:changed="onPageChanged"
    @package:delete="onPackageDeleteRequest"
    @sort:changed="requestPackagesList"
  >
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
