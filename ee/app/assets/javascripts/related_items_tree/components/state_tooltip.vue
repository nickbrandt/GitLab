<script>
import { GlTooltip } from '@gitlab/ui';

import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    getTargetRef: {
      type: Function,
      required: true,
    },
    isOpen: {
      type: Boolean,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    createdAt: {
      type: String,
      required: true,
    },
    closedAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    stateText() {
      return this.isOpen ? __('Opened') : __('Closed');
    },
    createdAtInWords() {
      return this.getTimestampInWords(this.createdAt);
    },
    closedAtInWords() {
      return this.getTimestampInWords(this.closedAt);
    },
    createdAtTimestamp() {
      return this.getTimestamp(this.createdAt);
    },
    closedAtTimestamp() {
      return this.getTimestamp(this.closedAt);
    },
    stateTimeInWords() {
      return this.isOpen ? this.createdAtInWords : this.closedAtInWords;
    },
    stateTimestamp() {
      return this.isOpen ? this.createdAtTimestamp : this.closedAtTimestamp;
    },
  },
  methods: {
    getTimestamp(rawTimestamp) {
      return rawTimestamp ? formatDate(new Date(rawTimestamp)) : '';
    },
    getTimestampInWords(rawTimestamp) {
      return rawTimestamp ? this.timeFormatted(rawTimestamp) : '';
    },
  },
};
</script>

<template>
  <gl-tooltip :target="getTargetRef()">
    <span class="bold">
      {{ stateText }}
    </span>
    {{ stateTimeInWords }}
    <br />
    <span class="text-tertiary">
      {{ stateTimestamp }}
    </span>
  </gl-tooltip>
</template>
