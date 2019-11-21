<script>
import { __ } from '~/locale';
import Sortable from 'sortablejs';
import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import IssueWeight from 'ee/boards/components/issue_card_weight.vue';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import sortableConfig from 'ee/sortable/sortable_config';
import { GlLoadingIcon } from '@gitlab/ui';
import AddIssuableForm from './add_issuable_form.vue';
import { issuableIconMap, issuableQaClassMap } from '../constants';

export default {
  name: 'RelatedIssuesBlock',
  directives: {
    tooltip,
  },
  components: {
    Icon,
    AddIssuableForm,
    RelatedIssuableItem,
    GlLoadingIcon,
    IssueWeight,
    IssueDueDate,
  },
  props: {
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
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
    isFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    title: {
      type: String,
      required: false,
      default: __('Related issues'),
    },
    issuableType: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasRelatedIssues() {
      return this.relatedIssues.length > 0;
    },
    shouldShowTokenBody() {
      return this.hasRelatedIssues || this.isFetching;
    },
    hasBody() {
      return this.isFormVisible || this.shouldShowTokenBody;
    },
    badgeLabel() {
      return this.isFetching && this.relatedIssues.length === 0 ? '...' : this.relatedIssues.length;
    },
    hasHelpPath() {
      return this.helpPath.length > 0;
    },
    issuableTypeIcon() {
      return issuableIconMap[this.issuableType];
    },
    qaClass() {
      return issuableQaClassMap[this.issuableType];
    },
    validIssueWeight() {
      if (this.issue) {
        return this.issue.weight >= 0;
      }

      return false;
    },
  },
  mounted() {
    if (this.canReorder) {
      this.sortable = Sortable.create(
        this.$refs.list,
        Object.assign({}, sortableConfig, {
          onStart: this.addDraggingCursor,
          onEnd: this.reordered,
        }),
      );
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
    issuableOrderingId({ epic_issue_id: epicIssueId, id }) {
      return this.issuableType === 'issue' ? epicIssueId : id;
    },
  },
};
</script>

<template>
  <div class="related-issues-block">
    <div class="card card-slim">
      <div :class="{ 'panel-empty-heading border-bottom-0': !hasBody }" class="card-header">
        <h3 class="card-title mt-0 mb-0 h5">
          {{ title }}
          <a v-if="hasHelpPath" :href="helpPath">
            <i
              class="related-issues-header-help-icon fa fa-question-circle"
              :aria-label="__('Read more about related issues')"
            ></i>
          </a>
          <div class="d-inline-flex lh-100 align-middle">
            <div
              class="js-related-issues-header-issue-count related-issues-header-issue-count issue-count-badge mx-1 border-width-1px border-style-solid border-color-default"
            >
              <span class="issue-count-badge-count">
                <icon :name="issuableTypeIcon" class="mr-1 text-secondary" />
                {{ badgeLabel }}
              </span>
            </div>
            <button
              v-if="canAdmin"
              ref="issueCountBadgeAddButton"
              type="button"
              :class="qaClass"
              class="js-issue-count-badge-add-button issue-count-badge-add-button btn btn-sm btn-default"
              :aria-label="__('Add an issue')"
              data-placement="top"
              data-qa-selector="related_issues_plus_button"
              @click="$emit('toggleAddRelatedIssuesForm', $event)"
            >
              <i class="fa fa-plus" aria-hidden="true"></i>
            </button>
          </div>
        </h3>
      </div>
      <div
        v-if="isFormVisible"
        :class="{
          'related-issues-add-related-issues-form-with-break': hasRelatedIssues,
        }"
        class="js-add-related-issues-form-area card-body"
      >
        <add-issuable-form
          :is-submitting="isSubmitting"
          :issuable-type="issuableType"
          :input-value="inputValue"
          :pending-references="pendingReferences"
          :auto-complete-sources="autoCompleteSources"
          :path-id-separator="pathIdSeparator"
          @pendingIssuableRemoveRequest="$emit('pendingIssuableRemoveRequest', $event)"
          @addIssuableFormInput="$emit('addIssuableFormInput', $event)"
          @addIssuableFormBlur="$emit('addIssuableFormBlur', $event)"
          @addIssuableFormSubmit="$emit('addIssuableFormSubmit', $event)"
          @addIssuableFormCancel="$emit('addIssuableFormCancel', $event)"
        />
      </div>
      <div
        v-if="shouldShowTokenBody"
        :class="{ 'sortable-container': canReorder }"
        class="related-issues-token-body"
      >
        <div v-if="isFetching" class="related-issues-loading-icon qa-related-issues-loading-icon">
          <gl-loading-icon
            ref="loadingIcon"
            label="Fetching related issues"
            class="prepend-top-5"
          />
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
              :created-at="issue.created_at"
              :closed-at="issue.closed_at"
              :can-remove="canAdmin"
              :can-reorder="canReorder"
              :path-id-separator="pathIdSeparator"
              event-namespace="relatedIssue"
              class="qa-related-issuable-item"
              @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
            >
              <span v-if="validIssueWeight" slot="weight" class="order-md-1">
                <issue-weight
                  :weight="issue.weight"
                  class="item-weight d-flex align-items-center"
                  tag-name="span"
                />
              </span>

              <span v-if="issue.due_date" slot="dueDate" class="order-md-1">
                <issue-due-date
                  :date="issue.due_date"
                  tooltip-placement="top"
                  css-class="item-due-date d-flex align-items-center"
                />
              </span>
            </related-issuable-item>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
