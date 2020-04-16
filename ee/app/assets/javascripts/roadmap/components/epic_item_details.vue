<script>
import { GlButton, GlIcon, GlTooltip } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlIcon,
    GlTooltip,
  },
  props: {
    epic: {
      type: Object,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    timeframeString: {
      type: String,
      required: true,
    },
  },
  computed: {
    isEpicGroupDifferent() {
      return this.currentGroupId !== this.epic.groupId;
    },
    isExpandIconHidden() {
      return this.epic.isChildEpic || !this.epic.children?.edges?.length;
    },
    expandIconName() {
      return this.epic.isChildEpicShowing ? 'chevron-down' : 'chevron-right';
    },
    expandIconLabel() {
      return this.epic.isChildEpicShowing ? __('Collapse child epics') : __('Expand child epics');
    },
    childEpicsCount() {
      return this.epic.isChildEpic ? '-' : this.epic.children?.edges?.length || 0;
    },
    childEpicsCountText() {
      return Number.isInteger(this.childEpicsCount)
        ? n__(`%d child epic`, `%d child epics`, this.childEpicsCount)
        : '';
    },
  },
  methods: {
    toggleIsEpicExpanded() {
      eventHub.$emit('toggleIsEpicExpanded', this.epic.id);
    },
  },
};
</script>

<template>
  <div class="epic-details-cell d-flex align-items-start p-2" data-qa-selector="epic_details_cell">
    <gl-button
      :class="{ invisible: isExpandIconHidden }"
      variant="link"
      :aria-label="expandIconLabel"
      @click="toggleIsEpicExpanded"
    >
      <gl-icon :name="expandIconName" class="text-secondary" aria-hidden="true" />
    </gl-button>
    <div class="overflow-hidden flex-grow-1" :class="[epic.isChildEpic ? 'ml-4 mr-2' : 'mx-2']">
      <a :href="epic.webUrl" :title="epic.title" class="epic-title d-block text-body bold">
        {{ epic.title }}
      </a>
      <div class="epic-group-timeframe d-flex text-secondary">
        <p v-if="isEpicGroupDifferent" :title="epic.groupFullName" class="epic-group">
          {{ epic.groupName }}
        </p>
        <span class="mx-1" aria-hidden="true">&middot;</span>
        <p class="epic-timeframe" :title="timeframeString">{{ timeframeString }}</p>
      </div>
    </div>
    <div
      ref="childEpicsCount"
      :class="{ invisible: epic.isChildEpic }"
      class="d-flex text-secondary text-nowrap"
    >
      <gl-icon name="epic" class="align-text-bottom mr-1" aria-hidden="true" />
      <p class="m-0" :aria-label="childEpicsCountText">{{ childEpicsCount }}</p>
    </div>
    <gl-tooltip v-if="!epic.isChildEpic" :target="() => $refs.childEpicsCount">
      {{ childEpicsCountText }}
    </gl-tooltip>
  </div>
</template>
