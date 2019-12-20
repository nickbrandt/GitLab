<script>
import { mapActions, mapState } from 'vuex';
import { debounce } from 'underscore';
import { GlTabs, GlTab, GlFormInput } from '@gitlab/ui';
import { DEFAULT_SEARCH_DELAY } from '../store/constants';

export default {
  name: 'GeoDesignsFilterBar',
  components: {
    GlTabs,
    GlTab,
    GlFormInput,
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
    ...mapActions(['setFilter', 'setSearch', 'fetchDesigns']),
    filterChange(filterIndex) {
      this.setFilter(filterIndex);
      this.fetchDesigns();
    },
  },
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
    <template v-slot:tabs-end>
      <div class="d-flex align-items-center ml-auto">
        <gl-form-input v-model="search" type="text" :placeholder="__(`Filter by name...`)" />
      </div>
    </template>
  </gl-tabs>
</template>
