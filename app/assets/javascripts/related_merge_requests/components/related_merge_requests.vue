<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';

export default {
  name: 'RelatedMergeRequests',
  components: {
    Icon,
    GlLoadingIcon,
    RelatedIssuableItem,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    projectNamespace: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isFetchingMergeRequests', 'mergeRequests']),
  },
  mounted() {
    this.setInitialState({ apiEndpoint: this.endpoint });
    this.fetchMergeRequests();
  },
  methods: {
    ...mapActions(['setInitialState', 'fetchMergeRequests']),
    getAssignees(mr) {
      if (mr.assignees) {
        return mr.assignees;
      }

      return mr.assignee ? [mr.assignee] : [];
    },
  },
};
</script>

<template>
  <div class="card-slim mt-3">
    <div class="card-header">
      <div class="card-title mt-0 mb-0 h5 merge-requests-title">
        <span class="mr-1">
          {{ __('Related merge requests') }}
        </span>
        <div class="d-inline-flex lh-100 align-middle">
          <div class="mr-count-badge">
            <div class="mr-count-badge-count">
              <svg class="s16 mr-1 text-secondary">
                <icon name="merge-request" class="mr-1 text-secondary" />
              </svg>
              <span class="js-items-count">{{ mergeRequests.length }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div>
      <div
        v-if="isFetchingMergeRequests"
        class="related-related-merge-requests-icon qa-related-merge-requests-loading-icon"
      >
        <gl-loading-icon label="Fetching related merge requests" class="py-2" />
      </div>
      <ul v-else class="content-list related-items-list">
        <li v-for="mr in mergeRequests" :key="mr.id" class="list-item pt-0 pb-0">
          <related-issuable-item
            :id-key="mr.id"
            :display-reference="mr.reference"
            :title="mr.title"
            :milestone="mr.milestone"
            :assignees="getAssignees(mr)"
            :created-at="mr.created_at"
            :closed-at="mr.closed_at"
            :path="mr.web_url"
            :state="mr.state"
            :is-merge-request="true"
            :pipeline-status="mr.head_pipeline && mr.head_pipeline.detailed_status"
            path-id-separator="!"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
