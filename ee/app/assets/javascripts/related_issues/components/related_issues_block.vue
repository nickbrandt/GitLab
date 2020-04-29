<script>
import { GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import AddIssuableForm from './add_issuable_form.vue';
import RelatedIssuesList from './related_issues_list.vue';
import {
  issuableIconMap,
  issuableQaClassMap,
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
} from '../constants';

export default {
  name: 'RelatedIssuesBlock',
  components: {
    Icon,
    GlLink,
    AddIssuableForm,
    RelatedIssuesList,
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
    issuableType: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasRelatedIssues() {
      return this.relatedIssues.length > 0;
    },
    categorisedIssues() {
      return Object.values(linkedIssueTypesMap)
        .map(linkType => ({
          linkType,
          issues: this.relatedIssues.filter(issue => issue.linkType === linkType),
        }))
        .filter(obj => obj.issues.length > 0);
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
  },
  created() {
    this.linkedIssueTypesTextMap = linkedIssueTypesTextMap;
  },
};
</script>

<template>
  <div id="related-issues" class="related-issues-block">
    <div class="card card-slim">
      <div :class="{ 'panel-empty-heading border-bottom-0': !hasBody }" class="card-header">
        <h3 class="card-title mt-0 mb-0 h5 position-relative">
          <gl-link
            id="user-content-related-issues"
            class="anchor position-absolute text-decoration-none"
            href="#related-issues"
            aria-hidden="true"
          />
          {{ __('Linked issues') }}
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
        class="linked-issues-card-body bg-gray-light"
        :class="{
          'gl-p-3-deprecated-no-really-do-not-use-me': isFormVisible || shouldShowTokenBody,
        }"
      >
        <div
          v-if="isFormVisible"
          class="js-add-related-issues-form-area card-body bordered-box bg-white"
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
        <template v-if="shouldShowTokenBody">
          <related-issues-list
            v-for="category in categorisedIssues"
            :key="category.linkType"
            :heading="linkedIssueTypesTextMap[category.linkType]"
            :can-admin="canAdmin"
            :can-reorder="canReorder"
            :is-fetching="isFetching"
            :issuable-type="issuableType"
            :path-id-separator="pathIdSeparator"
            :related-issues="category.issues"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
            @saveReorder="$emit('saveReorder', $event)"
          />
        </template>
      </div>
    </div>
  </div>
</template>
