<script>
import { mapActions, mapState } from 'vuex';
import { debounce } from 'underscore';
import { GlTabs, GlTab, GlFormInput, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { DEFAULT_SEARCH_DELAY, ACTION_TYPES } from '../store/constants';

export default {
  name: 'GeoReplicableFilterBar',
  components: {
    GlTabs,
    GlTab,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    Icon,
  },
  computed: {
    ...mapState(['currentFilterIndex', 'filterOptions', 'searchFilter', 'replicableType']),
    search: {
      get() {
        return this.searchFilter;
      },
      set: debounce(function debounceSearch(newVal) {
        this.setSearch(newVal);
        this.fetchReplicableItems();
      }, DEFAULT_SEARCH_DELAY),
    },
  },
  methods: {
    ...mapActions(['setFilter', 'setSearch', 'fetchReplicableItems', 'initiateAllReplicableSyncs']),
    filterChange(filterIndex) {
      this.setFilter(filterIndex);
      this.fetchReplicableItems();
    },
  },
  actionTypes: ACTION_TYPES,
};
</script>

<template>
  <gl-tabs :value="currentFilterIndex" @input="filterChange">
    <gl-tab
      v-for="(filter, index) in filterOptions"
      :key="index"
      :title="filter"
      title-item-class="text-capitalize"
    />
    <template #tabs-end>
      <div class="d-flex align-items-center ml-auto">
        <gl-form-input v-model="search" type="text" :placeholder="__(`Filter by name...`)" />
        <gl-dropdown class="ml-2">
          <template #button-content>
            <span>
              <icon name="cloud-gear" />
              {{ __('Batch operations') }}
              <icon name="chevron-down" />
            </span>
          </template>
          <gl-dropdown-item @click="initiateAllReplicableSyncs($options.actionTypes.RESYNC)">{{
            __(`Resync all ${replicableType}`)
          }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
    </template>
  </gl-tabs>
</template>
