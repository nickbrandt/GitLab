<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  props: {
    eventId: {
      type: Number,
      required: true,
    },
    eventTimeStamp: {
      type: Number,
      required: true,
    },
  },
  mixins: [
    timeAgoMixin,
  ],
  directives: {
    tooltip,
  },
  computed: {
    timeStamp() {
      return new Date(this.eventTimeStamp * 1000);
    },
    timeStampString() {
      return formatDate(this.timeStamp);
    },
  },
};
</script>

<template>
  <div
    class="node-detail-value"
  >
<<<<<<< HEAD
    <strong>
      {{eventId}}
    </strong>
    <span
      v-tooltip
      class="event-status-timestamp"
      data-placement="bottom"
      :title="timeStampString"
||||||| parent of c3efd8e0d8... Merge branch 'kp-fix-geo-admin-bugs' into 'master'
    <strong>
      {{ eventId }}
    </strong>
    <span
      v-tooltip
      class="event-status-timestamp"
      data-placement="bottom"
      :title="timeStampString"
=======
    <template v-if="eventTimeStamp">
      <strong>
        {{ eventId }}
      </strong>
      <span
        v-tooltip
        v-if="eventTimeStamp"
        class="event-status-timestamp"
        data-placement="bottom"
        :title="timeStampString"
      >
        ({{ timeFormated(timeStamp) }})
      </span>
    </template>
    <strong
      v-else
>>>>>>> c3efd8e0d8... Merge branch 'kp-fix-geo-admin-bugs' into 'master'
    >
<<<<<<< HEAD
      ({{timeFormated(timeStamp)}})
    </span>
||||||| parent of c3efd8e0d8... Merge branch 'kp-fix-geo-admin-bugs' into 'master'
      ({{ timeFormated(timeStamp) }})
    </span>
=======
      {{ __('Not available') }}
    </strong>
>>>>>>> c3efd8e0d8... Merge branch 'kp-fix-geo-admin-bugs' into 'master'
  </div>
</template>
