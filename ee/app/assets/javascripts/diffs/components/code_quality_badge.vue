<script>
import { GlBadge, GlTooltipDirective, GlModalDirective, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import CodequalityIssueBody from '~/reports/codequality_report/components/codequality_issue_body.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    CodequalityIssueBody,
    GlBadge,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    badgeTitle: s__('CodeQuality|Code quality'),
    badgeTooltip: s__('CodeQuality|Some changes in this file degrade the code quality.'),
    modalTitle: s__('CodeQuality|New code quality degradations in this file'),
  },
  modalCloseButton: {
    text: __('Close'),
    attributes: [{ variant: 'info' }],
  },
  props: {
    fileName: {
      type: String,
      required: true,
    },
    codequalityDiff: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    visible() {
      return this.glFeatures.codequalityMrDiff;
    },
    degradations() {
      return this.codequalityDiff.map((degradation) => {
        return {
          name: degradation.description,
          path: this.fileName,
          severity: degradation.severity,
        };
      });
    },
  },
};
</script>

<template>
  <span v-if="visible">
    <gl-badge
      v-gl-modal="`codequality-details-${fileName}`"
      v-gl-tooltip
      :title="$options.i18n.badgeTooltip"
      class="gl-display-inline-block"
      icon="information"
      href="#"
    >
      {{ $options.i18n.badgeTitle }}
    </gl-badge>
    <gl-modal
      :modal-id="`codequality-details-${fileName}`"
      :title="$options.i18n.modalTitle"
      :action-primary="$options.modalCloseButton"
    >
      <codequality-issue-body
        v-for="(degradation, index) in degradations"
        :key="index"
        :issue="degradation"
      />
    </gl-modal>
  </span>
</template>
