<script>
import { GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import {
  approximateDuration,
  differenceInSeconds,
  formatDate,
  getDayDifference,
} from '~/lib/utils/datetime_utility';

const DAYS_TO_EXPIRE_SOON = 7;

export default {
  name: 'ExpiresAt',
  components: { GlSprintf },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    date: {
      validator: prop => typeof prop === 'string' || prop === null,
      required: true,
    },
  },
  computed: {
    noExpirationSet() {
      return this.date === null;
    },
    parsed() {
      return new Date(this.date);
    },
    differenceInSeconds() {
      return differenceInSeconds(new Date(), this.parsed);
    },
    isExpired() {
      return this.differenceInSeconds <= 0;
    },
    inWords() {
      return approximateDuration(this.differenceInSeconds);
    },
    formatted() {
      return formatDate(this.parsed);
    },
    expiresSoon() {
      return getDayDifference(new Date(), this.parsed) < DAYS_TO_EXPIRE_SOON;
    },
    cssClass() {
      if (this.isExpired) {
        return 'gl-text-red-500';
      }

      if (this.expiresSoon) {
        return 'gl-text-orange-500';
      }

      return null;
    },
  },
};
</script>

<template>
  <span v-if="noExpirationSet">{{ __('No expiration set') }}</span>
  <span v-else v-gl-tooltip.hover :title="formatted" :class="cssClass">
    <span v-if="isExpired">{{ __('Expired') }}</span>
    <gl-sprintf v-else :message="__('in %{time}')">
      <template #time>
        {{ inWords }}
      </template>
    </gl-sprintf>
  </span>
</template>
