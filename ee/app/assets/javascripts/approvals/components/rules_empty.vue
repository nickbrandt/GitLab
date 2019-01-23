<script>
import { mapState } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Callout from '~/vue_shared/components/callout.vue';

const message = __(
  'There are no approvers explicitly added for this project. Members who are of Developer role or higher and code owners (if any) are eligible to approve.',
);

export default {
  components: {
    Callout,
    GlButton,
  },
  computed: {
    ...mapState(['settings']),
  },
  message,
};
</script>

<template>
  <callout class="m-0" category="info">
    <div>{{ $options.message }}</div>
    <div v-if="settings.canEdit" class="prepend-top-default">
      <gl-button class="btn-info btn-inverted" @click="$emit('click')">{{
        __('Add approvers')
      }}</gl-button>
    </div>
  </callout>
</template>
