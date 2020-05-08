<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Sortable from 'sortablejs';
import IssueWeight from 'ee/boards/components/issue_card_weight.vue';
import sortableConfig from 'ee/sortable/sortable_config';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'RelatedIssuesList',
  directives: {
    tooltip,
  },
  components: {
    GlLoadingIcon,
    IssueDueDate,
    IssueWeight,
    RelatedIssuableItem,
  },
  props: {
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    heading: {
      type: String,
      required: false,
      default: '',
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: true,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  mounted() {
    if (this.canReorder) {
      this.sortable = Sortable.create(this.$refs.list, {
        ...sortableConfig,
        onStart: this.addDraggingCursor,
        onEnd: this.reordered,
      });
    }
  },
  methods: {
    getBeforeAfterId(itemEl) {
      const prevItemEl = itemEl.previousElementSibling;
      const nextItemEl = itemEl.nextElementSibling;

      return {
        beforeId: prevItemEl && parseInt(prevItemEl.dataset.orderingId, 0),
        afterId: nextItemEl && parseInt(nextItemEl.dataset.orderingId, 0),
      };
    },
    reordered(event) {
      this.removeDraggingCursor();
      const { beforeId, afterId } = this.getBeforeAfterId(event.item);
      const { oldIndex, newIndex } = event;

      this.$emit('saveReorder', {
        issueId: parseInt(event.item.dataset.key, 10),
        oldIndex,
        newIndex,
        afterId,
        beforeId,
      });
    },
    addDraggingCursor() {
      document.body.classList.add('is-dragging');
    },
    removeDraggingCursor() {
      document.body.classList.remove('is-dragging');
    },
    issuableOrderingId({ epicIssueId, id }) {
      return this.issuableType === 'issue' ? epicIssueId : id;
    },
  },
};
</script>

<template>
  <div>
    <h4 v-if="heading" class="gl-font-base mt-0">{{ heading }}</h4>
    <div
      class="related-issues-token-body bordered-box bg-white"
      :class="{ 'sortable-container': canReorder }"
    >
      <div v-if="isFetching" class="related-issues-loading-icon qa-related-issues-loading-icon">
        <gl-loading-icon ref="loadingIcon" label="Fetching linked issues" class="prepend-top-5" />
      </div>
      <ul ref="list" :class="{ 'content-list': !canReorder }" class="related-items-list">
        <li
          v-for="issue in relatedIssues"
          :key="issue.id"
          :class="{
            'user-can-drag': canReorder,
            'sortable-row': canReorder,
            'card card-slim': canReorder,
          }"
          :data-key="issue.id"
          :data-ordering-id="issuableOrderingId(issue)"
          class="js-related-issues-token-list-item list-item pt-0 pb-0"
        >
          <related-issuable-item
            :id-key="issue.id"
            :display-reference="issue.reference"
            :confidential="issue.confidential"
            :title="issue.title"
            :path="issue.path"
            :state="issue.state"
            :milestone="issue.milestone"
            :assignees="issue.assignees"
            :created-at="issue.createdAt"
            :closed-at="issue.closedAt"
            :can-remove="canAdmin"
            :can-reorder="canReorder"
            :path-id-separator="pathIdSeparator"
            event-namespace="relatedIssue"
            class="qa-related-issuable-item"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
          >
            <span v-if="issue.weight > 0" slot="weight" class="order-md-1">
              <issue-weight
                :weight="issue.weight"
                class="item-weight d-flex align-items-center"
                tag-name="span"
              />
            </span>

            <span v-if="issue.dueDate" slot="dueDate" class="order-md-1">
              <issue-due-date
                :date="issue.dueDate"
                tooltip-placement="top"
                css-class="item-due-date d-flex align-items-center"
              />
            </span>
          </related-issuable-item>
        </li>
      </ul>
    </div>
  </div>
</template>
