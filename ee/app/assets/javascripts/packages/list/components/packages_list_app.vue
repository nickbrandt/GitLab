<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState, GlTab, GlTabs } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import PackageList from './packages_list.vue';
import PackageSort from './packages_sort.vue';
import { PACKAGE_REGISTRY_TABS } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlTab,
    GlTabs,
    PackageList,
    PackageSort,
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
    tabsToRender() {
      return PACKAGE_REGISTRY_TABS;
    },
  },
  mounted() {
    this.requestPackagesList();
  },
  methods: {
    ...mapActions(['requestPackagesList', 'requestDeletePackage', 'setSelectedType']),
    onPageChanged(page) {
      return this.requestPackagesList({ page });
    },
    onPackageDeleteRequest(item) {
      return this.requestDeletePackage(item);
    },
    tabChanged(e) {
      const selectedType = PACKAGE_REGISTRY_TABS[e];

      this.setSelectedType(selectedType);
      this.requestPackagesList();
    },
  },
};
</script>

<template>
  <gl-tabs @input="tabChanged">
    <template #tabs-end>
      <div class="align-self-center ml-auto">
        <package-sort @sort:changed="requestPackagesList" />
      </div>
    </template>

    <gl-tab v-for="(tab, index) in tabsToRender" :key="index" :title="tab.title">
      <package-list @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
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
    </gl-tab>
  </gl-tabs>
</template>
