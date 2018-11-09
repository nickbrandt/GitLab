<script>
import { mapState } from 'vuex';

import IssuableBody from '~/issue_show/components/app.vue';
import RelatedIssues from 'ee/related_issues/components/related_issues_root.vue';

export default {
  components: {
    IssuableBody,
    RelatedIssues,
  },
  computed: {
    ...mapState([
      'endpoint',
      'updateEndpoint',
      'issueLinksEndpoint',
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
    <related-issues
      :endpoint="issueLinksEndpoint"
      :can-admin="canAdmin"
      :can-reorder="canAdmin"
      :allow-auto-complete="false"
      title="Issues"
    />
  </div>
</template>
