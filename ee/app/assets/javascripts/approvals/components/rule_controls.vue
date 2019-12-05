<script>
import { mapState, mapActions } from 'vuex';
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
  computed: {
    ...mapState(['settings']),
  },
  methods: {
    ...mapActions(['requestEditRule', 'requestDeleteRule']),
  },
};
</script>

<template>
  <div>
    <gl-button variant="none" @click="requestEditRule(rule)">
      <span>{{ __('Edit') }}</span>
    </gl-button>
    <gl-button
      class="prepend-left-8 btn btn-inverted"
      variant="danger"
      @click="requestDeleteRule(rule)"
    >
      <icon name="remove" :aria-label="__('Remove')" />
    </gl-button>
  </div>
</template>
