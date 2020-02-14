<script>
import { GlIcon, GlDropdown, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { SELECTIVE_SYNC_SHARDS } from '../constants';

export default {
  name: 'GeoNodeFormShards',
  components: {
    GlIcon,
    GlDropdown,
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
  computed: {
    dropdownTitle() {
      if (this.selectedShards.length === 0) {
        return __('Select shards to replicate');
      }
      return sprintf(__('Shards selected: %{count}'), { count: this.selectedShards.length });
    },
    noSyncShards() {
      return this.syncShardsOptions.length === 0;
    },
  },
  methods: {
    toggleShard(shard) {
      const index = this.selectedShards.findIndex(value => value === shard.value);
      if (index > -1) {
        this.$emit('removeSyncOption', { key: SELECTIVE_SYNC_SHARDS, index });
      } else {
        this.$emit('addSyncOption', { key: SELECTIVE_SYNC_SHARDS, value: shard.value });
      }
    },
    isSelected(shard) {
      return this.selectedShards.includes(shard.value);
    },
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownTitle">
    <li v-for="shard in syncShardsOptions" :key="shard.value">
      <gl-button class="d-flex align-items-center" @click="toggleShard(shard)">
        <gl-icon :class="[{ invisible: !isSelected(shard) }]" name="mobile-issue-close" />
        <span class="ml-1">{{ shard.label }}</span>
      </gl-button>
    </li>
    <div v-if="noSyncShards" class="text-secondary p-2">{{ __('Nothing found…') }}</div>
  </gl-dropdown>
</template>
