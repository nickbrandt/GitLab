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
    ...mapActions({ openCreateModal: 'createModal/open' }),
    ...mapActions({ openDeleteModal: 'deleteModal/open' }),
  },
};
</script>

<template>
  <div>
    <gl-button variant="none" @click="openCreateModal(rule)"> <span>Edit</span> </gl-button
    ><gl-button
      v-if="!rule.isFallback"
      class="prepend-left-8 btn-inverted"
      variant="remove"
      @click="openDeleteModal(rule)"
    >
      <icon name="remove" :aria-label="__('Remove')" />
    </gl-button>
  </div>
</template>
