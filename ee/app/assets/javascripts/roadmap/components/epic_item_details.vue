<script>
import { GlIcon, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
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
      return this.epic.isChildEpic || !this.epic?.children?.edges?.length;
    },
    expandIconName() {
      return this.epic.isChildEpicShowing ? 'angle-down' : 'angle-right';
    },
    expandIconLabel() {
      return this.epic.isChildEpicShowing ? __('Collapse') : __('Expand');
    },
    childEpicsCount() {
      return this.epic.isChildEpic ? '-' : this.epic?.children?.edges?.length || 0;
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
  <div class="epic-details-cell d-flex p-2" data-qa-selector="epic_details_cell">
    <div
      :class="{ invisible: isExpandIconHidden }"
      class="epic-details-cell-expand-icon cursor-pointer"
      tabindex="0"
      @click="toggleIsEpicExpanded"
      @keydown.enter="toggleIsEpicExpanded"
    >
      <gl-icon
        :name="expandIconName"
        class="text-secondary width"
        :aria-label="expandIconLabel"
        :size="12"
      />
    </div>
    <div class="overflow-hidden flex-grow-1" :class="[epic.isChildEpic ? 'ml-4 mr-2' : 'mx-2']">
      <a :href="epic.webUrl" :title="epic.title" class="epic-title d-block text-body bold">
        {{ epic.title }}
      </a>
      <div class="epic-group-timeframe text-secondary">
        <span v-if="isEpicGroupDifferent" :title="epic.groupFullName" class="epic-group">
          {{ epic.groupName }} &middot;
        </span>
        <span class="epic-timeframe" :title="timeframeString">{{ timeframeString }}</span>
      </div>
    </div>
    <div
      ref="childEpicsCount"
      :class="['text-secondary', 'text-nowrap', { invisible: epic.isChildEpic }]"
    >
      <gl-icon name="epic" class="align-text-bottom" />
      {{ childEpicsCount }}
    </div>
    <gl-tooltip v-if="!epic.isChildEpic" :target="() => $refs.childEpicsCount">
      {{ n__(`%d child epic`, `%d child epics`, childEpicsCount) }}
    </gl-tooltip>
  </div>
</template>
