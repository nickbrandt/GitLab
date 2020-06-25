<script>
import { sprintf, s__ } from '~/locale';
import { GlAvatar, GlAvatarLink, GlTooltipDirective } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Approvers from './approvers.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    Approvers,
    GlAvatar,
    GlAvatarLink,
  },
  mixins: [timeagoMixin],
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasCiPipeline() {
      return Boolean(this.mergeRequest.pipeline_status);
    },
    pipelineCiStatus() {
      const details = this.mergeRequest.pipeline_status;
      return { ...details, group: details.group || details.label };
    },
    pipelineTitle() {
      const { tooltip } = this.mergeRequest.pipeline_status;
      return sprintf(s__('PipelineStatusTooltip|Pipeline: %{ci_status}'), {
        ci_status: tooltip,
      });
    },
    timeAgoString() {
      return sprintf(s__('merged %{time_ago}'), {
        time_ago: this.timeFormatted(this.mergeRequest.merged_at),
      });
    },
    timeTooltip() {
      return this.tooltipTitle(this.mergeRequest.merged_at);
    },
  },
  strings: {
    createdBy: s__('ComplianceDashboard|created by:'),
  },
};
</script>

<template>
  <li class="merge-request">
    <div class="issuable-info-container">
      <div class="issuable-main-info">
        <div class="title">
          <a :href="mergeRequest.path">
            {{ mergeRequest.title }}
          </a>
        </div>
        <span class="gl-text-gray-700">
          {{ mergeRequest.issuable_reference }}
        </span>
        <span class="issuable-authored gl-text-gray-700 d-inline-flex align-items-center">
          - {{ $options.strings.createdBy }}
          <gl-avatar-link
            :key="mergeRequest.author.id"
            :title="mergeRequest.author.name"
            :href="mergeRequest.author.web_url"
            :data-user-id="mergeRequest.author.id"
            :data-name="mergeRequest.author.name"
            class="d-inline-flex align-items-center ml-2 author-link js-user-link"
          >
            <gl-avatar
              :src="mergeRequest.author.avatar_url"
              :entity-id="mergeRequest.author.id"
              :entity-name="mergeRequest.author.name"
              :size="16"
              class="mr-1"
            />
            <span>{{ mergeRequest.author.name }}</span>
          </gl-avatar-link>
        </span>
      </div>

      <div class="issuable-meta">
        <ul class="controls">
          <li v-if="hasCiPipeline" class="mr-2">
            <a :href="pipelineCiStatus.details_path">
              <ci-icon
                v-gl-tooltip.left="pipelineTitle"
                class="d-flex"
                :status="pipelineCiStatus"
              />
            </a>
          </li>
          <approvers :approvers="mergeRequest.approved_by_users" />
        </ul>
        <span class="gl-text-gray-700">
          <time v-gl-tooltip.bottom="timeTooltip">{{ timeAgoString }}</time>
        </span>
      </div>
    </div>
  </li>
</template>
