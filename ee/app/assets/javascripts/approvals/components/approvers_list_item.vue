<script>
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import Avatar from '~/vue_shared/components/project_avatar/default.vue';
import { TYPE_USER, TYPE_GROUP } from '../constants';

const types = [TYPE_USER, TYPE_GROUP];

export default {
  components: {
    GlButton,
    Icon,
    Avatar,
  },
  props: {
    approver: {
      type: Object,
      required: true,
      validator: ({ type }) => type && types.indexOf(type) >= 0,
    },
  },
  computed: {
    isGroup() {
      return this.approver.type === TYPE_GROUP;
    },
    displayName() {
      return this.isGroup ? this.approver.full_path : this.approver.name;
    },
  },
};
</script>

<template>
  <transition name="fade">
    <li class="settings-flex-row">
      <div class="px-3 d-flex align-items-center">
        <avatar :project="approver" :size="24" /><span>{{ displayName }}</span>
        <gl-button variant="none" class="ml-auto" @click="$emit('remove', approver)">
          <icon name="remove" :aria-label="__('Remove')" />
        </gl-button>
      </div>
    </li>
  </transition>
</template>
