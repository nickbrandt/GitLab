<script>
import { mapState, mapGetters } from 'vuex';

import { PathIdSeparator } from 'ee/related_issues/constants';

import RelatedItems from 'ee/related_issues/components/related_issues_root.vue';
import IssuableBody from '~/issue_show/components/app.vue';
import IssuableSidebar from '~/issuable_sidebar/components/sidebar_app.vue';

import EpicSidebar from './epic_sidebar.vue';

export default {
  PathIdSeparator,
  components: {
    IssuableBody,
    IssuableSidebar,
    RelatedItems,
    EpicSidebar,
  },
  computed: {
    ...mapState([
      'endpoint',
      'updateEndpoint',
      'groupPath',
      'markdownPreviewPath',
      'markdownDocsPath',
      'canUpdate',
      'canDestroy',
      'canAdmin',
      'initialTitleHtml',
      'initialTitleText',
      'initialDescriptionHtml',
      'initialDescriptionText',
      'lockVersion',
      'sidebarCollapsed',
    ]),
    ...mapGetters(['isUserSignedIn']),
    isVueIssuableEpicSidebarEnabled() {
      return gon.features && gon.features.vueIssuableEpicSidebar;
    },
    sidebarStatusClass() {
      return this.sidebarCollapsed ? 'right-sidebar-collapsed' : 'right-sidebar-expanded';
    },
  },
};
</script>

<template>
  <div class="issuable-details content-block">
    <div class="detail-page-description">
      <issuable-body
        :endpoint="endpoint"
        :update-endpoint="updateEndpoint"
        :project-path="groupPath"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :can-update="canUpdate"
        :can-destroy="canDestroy"
        :show-delete-button="canDestroy"
        :initial-title-html="initialTitleHtml"
        :initial-title-text="initialTitleText"
        :lock-version="lockVersion"
        :initial-description-html="initialDescriptionHtml"
        :initial-description-text="initialDescriptionText"
        :show-inline-edit-button="true"
        :enable-autocomplete="true"
        project-namespace
        issuable-ref
        issuable-type="epic"
      />
    </div>
    <issuable-sidebar
      v-if="isVueIssuableEpicSidebarEnabled"
      :signed-in="isUserSignedIn"
      :sidebar-status-class="sidebarStatusClass"
    />
    <epic-sidebar v-else />
  </div>
</template>
