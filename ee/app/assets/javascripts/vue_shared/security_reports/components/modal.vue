<script>
import { s__ } from '~/locale';
import Modal from '~/vue_shared/components/gl_modal.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import SafeLink from 'ee/vue_shared/components/safe_link.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import SeverityBadge from './severity_badge.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';

export default {
  components: {
    EventItem,
    ExpandButton,
    Icon,
    LoadingButton,
    Modal,
    SafeLink,
    SeverityBadge,
    SolutionCard,
    SplitButton,
  },
  props: {
    modal: {
      type: Object,
      required: true,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    canCreateIssuePermission: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateFeedbackPermission: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    actionButtons() {
      const buttons = [];
      const issueButton = {
        name: s__('ciReport|Create issue'),
        tagline: s__('ciReport|Investigate this vulnerability by creating an issue'),
        isLoading: this.modal.isCreatingNewIssue,
        action: 'createNewIssue',
      };
      const MRButton = {
        name: s__('ciReport|Create merge request'),
        tagline: s__('ciReport|Implement this solution by creating a merge request'),
        isLoading: this.modal.isCreatingMergeRequest,
        action: 'createMergeRequest',
      };

      if (!this.vulnerability.hasMergeRequest && this.remediation) {
        buttons.push(MRButton);
      }

      if (!this.vulnerability.hasIssue && this.canCreateIssuePermission) {
        buttons.push(issueButton);
      }

      return buttons;
    },
    revertTitle() {
      return this.vulnerability.isDismissed
        ? s__('ciReport|Undo dismiss')
        : s__('ciReport|Dismiss vulnerability');
    },
    hasDismissedBy() {
      return (
        this.vulnerability &&
        this.vulnerability.dismissalFeedback &&
        this.vulnerability.dismissalFeedback.pipeline &&
        this.vulnerability.dismissalFeedback.author
      );
    },
    project() {
      return this.modal.data.project || {};
    },
    solution() {
      return this.vulnerability && this.vulnerability.solution;
    },
    remediation() {
      return (
        this.vulnerability && this.vulnerability.remediations && this.vulnerability.remediations[0]
      );
    },
    renderSolutionCard() {
      return this.solution || this.remediation;
    },
    /**
     * The slot for the footer should be rendered if any of the conditions is true.
     */
    shouldRenderFooterSection() {
      return (
        !this.modal.isResolved &&
        (this.canCreateFeedbackPermission || this.canCreateIssuePermission)
      );
    },
    issueFeedback() {
      return this.vulnerability && this.vulnerability.issue_feedback;
    },
    mergeRequestFeedback() {
      return this.vulnerability && this.vulnerability.merge_request_feedback;
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
    valuedFields() {
      const { data } = this.modal;
      const result = {};

      Object.keys(data).forEach(key => {
        if (data[key].value && data[key].value.length) {
          result[key] = data[key];
        }
      });

      return result;
    },
  },
  methods: {
    handleDismissClick() {
      if (this.vulnerability.isDismissed) {
        this.$emit('revertDismissIssue');
      } else {
        this.$emit('dismissIssue');
      }
    },
    isLastValue(index, values) {
      return index < values.length - 1;
    },
    hasValue(field) {
      return field.value && field.value.length > 0;
    },
    hasInstances(field, key) {
      return key === 'instances' && this.hasValue(field);
    },
    hasIdentifiers(field, key) {
      return key === 'identifiers' && this.hasValue(field);
    },
    hasLinks(field, key) {
      return key === 'links' && this.hasValue(field);
    },
    hasSeverity(field, key) {
      return key === 'severity' && this.hasValue(field);
    },
  },
};
</script>
<template>
  <modal
    id="modal-mrwidget-security-issue"
    :header-title-text="modal.title"
    :class="{ 'modal-hide-footer': !shouldRenderFooterSection }"
    class="modal-security-report-dast"
  >
    <slot>
      <div class="border-white mb-0 px-3">
        <div v-for="(field, key, index) in valuedFields" :key="index" class="d-flex my-2">
          <label class="col-2 text-right font-weight-bold pl-0">{{ field.text }}:</label>
          <div class="col-10 pl-0 text-secondary">
            <div v-if="hasInstances(field, key)" class="info-well">
              <ul class="report-block-list">
                <li v-for="(instance, i) in field.value" :key="i" class="report-block-list-issue">
                  <div class="report-block-list-icon append-right-5 failed">
                    <icon :size="32" name="status_failed_borderless" />
                  </div>
                  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
                    <div class="report-block-list-issue-description-text">
                      {{ instance.method }}
                    </div>
                    <div class="report-block-list-issue-description-link">
                      <safe-link
                        :href="instance.uri"
                        target="_blank"
                        rel="noopener noreferrer nofollow"
                        class="break-link"
                      >
                        {{ instance.uri }}
                      </safe-link>
                    </div>
                    <expand-button v-if="instance.evidence">
                      <pre
                        slot="expanded"
                        class="block report-block-dast-code prepend-top-10 report-block-issue-code"
                      >
                      {{ instance.evidence }}</pre
                      >
                    </expand-button>
                  </div>
                </li>
              </ul>
            </div>
            <template v-else-if="hasIdentifiers(field, key)">
              <span v-for="(identifier, i) in field.value" :key="i">
                <safe-link
                  v-if="identifier.url"
                  :class="`js-link-${key}`"
                  :href="identifier.url"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ identifier.name }}
                </safe-link>
                <span v-else> {{ identifier.name }} </span>
                <span v-if="isLastValue(i, field.value)">,&nbsp;</span>
              </span>
            </template>
            <template v-else-if="hasLinks(field, key)">
              <span v-for="(link, i) in field.value" :key="i">
                <safe-link
                  :class="`js-link-${key}`"
                  :href="link.url"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ link.value || link.url }}
                </safe-link>
                <span v-if="isLastValue(i, field.value)">,&nbsp;</span>
              </span>
            </template>
            <template v-else-if="hasSeverity(field, key)">
              <severity-badge :severity="field.value" class="d-inline" />
            </template>
            <template v-else>
              <safe-link
                v-if="field.isLink"
                :class="`js-link-${key}`"
                :href="field.url"
                target="_blank"
              >
                {{ field.value }}
              </safe-link>
              <span v-else :class="{ 'text-capitalize': key === 'confidence' }">
                {{ field.value }}
              </span>
            </template>
          </div>
        </div>
      </div>

      <solution-card v-if="renderSolutionCard" :solution="solution" :remediation="remediation" />
      <hr v-else />

      <ul v-if="vulnerability.hasIssue || vulnerability.hasMergeRequest" class="notes card">
        <li v-if="vulnerability.hasIssue" class="note">
          <event-item
            type="issue"
            :project-name="project.value"
            :project-link="project.url"
            :author-name="issueFeedback.author.name"
            :author-username="issueFeedback.author.username"
            :action-link-text="`#${issueFeedback.issue_iid}`"
            :action-link-url="issueFeedback.issue_url"
          />
        </li>
        <li v-if="vulnerability.hasMergeRequest" class="note">
          <event-item
            type="mergeRequest"
            :project-name="project.value"
            :project-link="project.url"
            :author-name="mergeRequestFeedback.author.name"
            :author-username="mergeRequestFeedback.author.username"
            :action-link-text="`!${mergeRequestFeedback.merge_request_iid}`"
            :action-link-url="mergeRequestFeedback.merge_request_path"
          />
        </li>
      </ul>

      <div class="prepend-top-20 append-bottom-10">
        <div class="col-sm-12 text-secondary">
          <template v-if="hasDismissedBy">
            {{ s__('ciReport|Dismissed by') }}
            <a :href="vulnerability.dismissalFeedback.author.web_url" class="pipeline-id">
              @{{ vulnerability.dismissalFeedback.author.username }}
            </a>
            {{ s__('ciReport|on pipeline') }}
            <a :href="vulnerability.dismissalFeedback.pipeline.path" class="pipeline-id"
              >#{{ vulnerability.dismissalFeedback.pipeline.id }}</a
            >.
          </template>
          <a
            v-if="vulnerabilityFeedbackHelpPath"
            :href="vulnerabilityFeedbackHelpPath"
            class="js-link-vulnerabilityFeedbackHelpPath"
          >
            {{ s__('ciReport|Learn more about interacting with security reports (Alpha).') }}
          </a>
        </div>
      </div>

      <div v-if="modal.error" class="alert alert-danger">{{ modal.error }}</div>
    </slot>
    <div slot="footer">
      <template v-if="shouldRenderFooterSection">
        <button type="button" class="btn btn-default" data-dismiss="modal">
          {{ __('Cancel') }}
        </button>

        <loading-button
          v-if="canCreateFeedbackPermission"
          :loading="modal.isDismissingIssue"
          :disabled="modal.isDismissingIssue"
          :label="revertTitle"
          container-class="js-dismiss-btn btn btn-close"
          @click="handleDismissClick"
        />

        <split-button
          v-if="actionButtons.length > 1"
          :buttons="actionButtons"
          class="js-split-button"
          @createMergeRequest="$emit('createMergeRequest')"
          @createNewIssue="$emit('createNewIssue')"
        />

        <loading-button
          v-else-if="actionButtons.length > 0"
          :loading="actionButtons[0].isLoading"
          :disabled="actionButtons[0].isLoading"
          :label="actionButtons[0].name"
          container-class="btn btn-success btn-inverted"
          class="js-action-button"
          @click="$emit(actionButtons[0].action)"
        />
      </template>
    </div>
  </modal>
</template>
