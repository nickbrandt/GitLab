<script>
import { isEmpty } from 'lodash';
import { GlAlert, GlLink } from '@gitlab/ui';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlAlert,
    GlLink,
    TimeagoTooltip,
  },
  props: {
    user: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    erasedAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    isErasedByUser() {
      return !isEmpty(this.user);
    },
  },
};
</script>
<template>
  <div class="gl-mt-3">
    <gl-alert variant="warning" :dismissible="false">
      <template v-if="isErasedByUser">
        {{ s__('Job|Job has been erased by') }}
        <gl-link :href="user.web_url">{{ user.username }}</gl-link>
      </template>

      <template v-else>
        {{ s__('Job|Job has been erased') }}
      </template>

      <timeago-tooltip :time="erasedAt" />
    </gl-alert>
  </div>
</template>
