<script>
import { GlIcon, GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';

export default {
  name: 'GeoNodeFormShards',
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlButton,
  },
  props: {
    syncShardsOptions: {
      type: Array,
      required: true,
    },
    selectedShards: {
      type: Array,
      required: true,
    },
  },
  methods: {
    toggleShard(shard) {
      const index = this.selectedShards.findIndex(value => value === shard.value);
      if (index > -1) {
        this.$emit('removeSyncOption', { key: 'selectiveSyncShards', index });
      } else {
        this.$emit('addSyncOption', { key: 'selectiveSyncShards', value: shard.value });
      }
    },
    isSelected(shard) {
      return this.selectedShards.includes(shard.value);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="__('Select shards to replicate')">
    <gl-dropdown-item
      v-for="shard in syncShardsOptions"
      :key="shard.value"
      @click.stop.prevent="toggleShard(shard)"
    >
      <gl-button class="d-flex align-items-center" @click.stop.prevent="toggleShard(shard)">
        <gl-icon :class="[{ invisible: !isSelected(shard) }, 'mr-1']" name="mobile-issue-close" />
        <span>{{ shard.label }}</span>
      </gl-button>
    </gl-dropdown-item>
    <div v-if="syncShardsOptions === 0" class="text-secondary p-2">{{ __('Nothing found…') }}</div>
  </gl-dropdown>
</template>
