<script>
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';

export default {
  components: {
    EventItem,
  },
  props: {
    feedback: {
      type: Object,
      required: true,
    },
    project: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    eventText() {
      const { project, feedback } = this;
      const { pipeline } = feedback;

      const pipelineLink =
        pipeline && pipeline.path && pipeline.id
          ? `<a href="${pipeline.path}">#${pipeline.id}</a>`
          : null;

      const projectLink =
        project && project.url && project.value
          ? `<a href="${_.escape(project.url)}">${_.escape(project.value)}</a>`
          : null;

      if (pipelineLink && projectLink) {
        return sprintf(
          __('Dismissed on pipeline %{pipelineLink} at %{projectLink}'),
          { pipelineLink, projectLink },
          false,
        );
      } else if (pipelineLink && !projectLink) {
        return sprintf(__('Dismissed on pipeline %{pipelineLink}'), { pipelineLink }, false);
      } else if (!pipelineLink && projectLink) {
        return sprintf(__('Dismissed at %{projectLink}'), { projectLink }, false);
      }
      return __('Dismissed');
    },
  },
};
</script>

<template>
  <event-item
    :author="feedback.author"
    :created-at="feedback.created_at"
    icon-name="cancel"
    icon-style="ci-status-icon-pending"
  >
    <div v-html="eventText"></div>
  </event-item>
</template>
