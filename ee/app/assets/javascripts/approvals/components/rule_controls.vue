<script>
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    Icon,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['requestEditRule', 'requestDeleteRule']),
  },
};
</script>

<template>
  <div>
    <gl-button variant="none" @click="requestEditRule(rule)"> <span>Edit</span> </gl-button
    ><gl-button
      v-if="!rule.isFallback"
      class="prepend-left-8 btn-inverted"
      variant="remove"
      @click="requestDeleteRule(rule)"
    >
      <icon name="remove" :aria-label="__('Remove')" />
    </gl-button>
  </div>
</template>
