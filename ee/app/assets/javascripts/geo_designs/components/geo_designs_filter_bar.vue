<script>
import { mapActions, mapState } from 'vuex';
import { debounce } from 'underscore';
import { GlTabs, GlTab, GlFormInput, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { DEFAULT_SEARCH_DELAY, ACTION_TYPES } from '../store/constants';

export default {
  name: 'GeoDesignsFilterBar',
  components: {
    GlTabs,
    GlTab,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    Icon,
  },
  computed: {
    ...mapState(['currentFilterIndex', 'filterOptions', 'searchFilter']),
    search: {
      get() {
        return this.searchFilter;
      },
      set: debounce(function debounceSearch(newVal) {
        this.setSearch(newVal);
        this.fetchDesigns();
      }, DEFAULT_SEARCH_DELAY),
    },
  },
  methods: {
    ...mapActions(['setFilter', 'setSearch', 'fetchDesigns', 'initiateAllDesignSyncs']),
    filterChange(filterIndex) {
      this.setFilter(filterIndex);
      this.fetchDesigns();
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
          <gl-dropdown-item @click="initiateAllDesignSyncs($options.actionTypes.RESYNC)">{{
            __('Resync all designs')
          }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
    </template>
  </gl-tabs>
</template>
