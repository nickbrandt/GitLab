<script>
import { GlSprintf, GlCard } from '@gitlab/ui';
import { s__ } from '~/locale';
import ScheduleTimelineSection from './schedule/components/schedule_timeline_section.vue';
import { getTimeframeForWeeksView } from './schedule/utils';
import { PRESET_TYPES } from './schedule/constants';
import { getFormattedTimezone } from '../utils';

export const i18n = {
  title: s__('OnCallSchedules|On-call schedule'),
  scheduleForTz: s__('OnCallSchedules|On-call schedule for the %{tzShort}'),
};

export default {
  i18n,
  presetType: PRESET_TYPES.WEEKS,
  inject: ['timezones'],
  components: {
    GlSprintf,
    GlCard,
    ScheduleTimelineSection,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tzLong() {
      const selectedTz = this.timezones.find(tz => tz.identifier === this.schedule.timezone);
      return getFormattedTimezone(selectedTz);
    },
    timeframe() {
      return getTimeframeForWeeksView();
    },
  },
};
</script>

<template>
  <div>
    <h2>{{ $options.i18n.title }}</h2>
    <gl-card>
      <template #header>
        <h3 class="gl-font-weight-bold gl-font-lg gl-m-0">{{ schedule.name }}</h3>
      </template>

      <p class="gl-text-gray-500 gl-mb-5">
        <gl-sprintf :message="$options.i18n.scheduleForTz">
          <template #tzShort>{{ schedule.timezone }}</template>
        </gl-sprintf>
        | {{ tzLong }}
      </p>

      <div class="schedule-shell">
        <schedule-timeline-section :preset-type="$options.presetType" :timeframe="timeframe" />
      </div>
    </gl-card>
  </div>
</template>
