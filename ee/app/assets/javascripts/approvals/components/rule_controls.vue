<script>
import { mapState, mapActions } from 'vuex';
import { GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlDeprecatedButton,
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
    <gl-deprecated-button variant="none" @click="requestEditRule(rule)">
      <span>{{ __('Edit') }}</span>
    </gl-deprecated-button>
    <gl-deprecated-button
      class="gl-ml-3 btn btn-inverted"
      variant="danger"
      @click="requestDeleteRule(rule)"
    >
      <icon name="remove" :aria-label="__('Remove')" />
    </gl-deprecated-button>
  </div>
</template>
