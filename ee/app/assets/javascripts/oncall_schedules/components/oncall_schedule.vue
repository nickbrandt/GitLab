<script>
  import {GlSprintf, GlCard} from '@gitlab/ui';
  import {s__, __} from '~/locale';
  import ScheduleShell from './schedule/components/schedul_shell.vue';
  import {getTimeframeForPreset} from './schedule/utils/roadmap_utils';
  import {PRESET_TYPES} from "../../roadmap/constants";

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
      ScheduleShell,
    },
    props: {
      schedule: {
        type: Object,
        required: true,
      }
    },
    computed: {
      tzLong() {
        const selectedTz = this.timezones.find(tz => tz.identifier === this.schedule.timezone);
        return this.getFormattedTimezone(selectedTz);
      },
      timeframe() {
        return getTimeframeForPreset(
          PRESET_TYPES.WEEKS,
          window.innerWidth,
          // TODO $refs is never defined here: window.innerWidth - this.$refs.scheduleContainer.offsetLeft,
        );
      },
    },
    methods: {
      getFormattedTimezone(tz) {
        return __(`(UTC${tz.formatted_offset}) ${tz.abbr} ${tz.name}`);
      },
    },
  }
</script>

<template>
  <div>
    <h2 ref="title">{{$options.i18n.title}}</h2>
    <gl-card>
      <template #header>
        <span class="gl-font-weight-bold gl-font-lg">{{schedule.name}}</span>
      </template>

      <div class="gl-color-gray-500 gl-mb-5">
        <gl-sprintf :message="$options.i18n.scheduleForTz">
          <template #tzShort><span>{{schedule.timezone}}</span></template>
        </gl-sprintf>
        | <span>{{ tzLong }}</span>
      </div>

      <div ref="scheduleContainer" class="gl-w-full">
        <schedule-shell :preset-type="$options.presetType" :timeframe="timeframe" :epics="[]"/>
      </div>

    </gl-card>
  </div>
</template>
