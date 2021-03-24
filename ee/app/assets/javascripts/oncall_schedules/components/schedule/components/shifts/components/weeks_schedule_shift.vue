<script>
import RotationAssignee from 'ee/oncall_schedules/components/rotations/components/rotation_assignee.vue';
import { getPixelOffset, getPixelWidth } from './shift_utils';

export default {
  components: {
    RotationAssignee,
  },
  props: {
    shift: {
      type: Object,
      required: true,
    },
    shiftIndex: {
      type: Number,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    presetType: {
      type: String,
      required: true,
    },
    timelineWidth: {
      type: Number,
      required: true,
    },
    rotationLength: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shiftStyles() {
      const { timeframe, presetType, shift, timelineWidth } = this;

      return {
        left: getPixelOffset({
          timeframe,
          shift,
          timelineWidth,
          presetType,
        }),
        width: getPixelWidth({
          shift,
          timelineWidth,
          presetType,
        }),
      };
    },
    rotationAssigneeStyle() {
      const { left, width } = this.shiftStyles;
      return {
        left: `${left}px`,
        width: `${width}px`,
      };
    },
  },
};
</script>

<template>
  <rotation-assignee
    :assignee="shift.participant"
    :rotation-assignee-style="rotationAssigneeStyle"
    :rotation-assignee-starts-at="shift.startsAt"
    :rotation-assignee-ends-at="shift.endsAt"
    :shift-width="shiftStyles.width"
  />
</template>
