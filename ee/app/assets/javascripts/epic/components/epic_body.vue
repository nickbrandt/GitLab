<script>
import { mapState } from 'vuex';

import IssuableBody from '~/issue_show/components/app.vue';
import RelatedItems from 'ee/related_issues/components/related_issues_root.vue';

import EpicSidebar from './epic_sidebar.vue';

export default {
  epicsPathIdSeparator: '&',
  components: {
    IssuableBody,
    RelatedItems,
    EpicSidebar,
  },
  computed: {
    ...mapState([
      'endpoint',
      'updateEndpoint',
      'epicLinksEndpoint',
      'issueLinksEndpoint',
      'groupPath',
      'markdownPreviewPath',
      'markdownDocsPath',
      'canUpdate',
      'canDestroy',
      'canAdmin',
      'subepicsSupported',
      'initialTitleHtml',
      'initialTitleText',
      'initialDescriptionHtml',
      'initialDescriptionText',
    ]),
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
        :initial-description-html="initialDescriptionHtml"
        :initial-description-text="initialDescriptionText"
        :show-inline-edit-button="true"
        :enable-autocomplete="true"
        project-namespace=""
        issuable-ref=""
        issuable-type="epic"
      />
    </div>
    <related-items
      v-if="subepicsSupported"
      :endpoint="epicLinksEndpoint"
      :can-admin="canAdmin"
      :can-reorder="canAdmin"
      :allow-auto-complete="false"
      :path-id-separator="$options.epicsPathIdSeparator"
      :title="__('Epics')"
      :issuable-type="__('epic')"
      css-class="js-related-epics-block"
    />
    <related-items
      :endpoint="issueLinksEndpoint"
      :can-admin="canAdmin"
      :can-reorder="canAdmin"
      :allow-auto-complete="false"
      :title="__('Issues')"
      :issuable-type="__('issue')"
      css-class="js-related-issues-block"
      path-id-separator="#"
    />
    <epic-sidebar />
  </div>
</template>
