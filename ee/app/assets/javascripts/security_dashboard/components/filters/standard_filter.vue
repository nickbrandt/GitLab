<script>
import { isEqual, xor, without } from 'lodash';
import { ALL } from '../../store/modules/filters/constants';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  components: { FilterBody, FilterItem },
  props: {
    filter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedIds: [],
    };
  },
  computed: {
    options() {
      return this.filter.options;
    },
    selectedSet() {
      return new Set(this.selectedIds);
    },
    selectedOptions() {
      return this.options.filter((option) => this.selectedSet.has(option.id));
    },
    selectedIdsWithoutAll() {
      return without(this.selectedIds, ALL);
    },
    // This is used as variables for the vulnerability list Apollo query.
    filterObject() {
      return { [this.filter.id]: this.selectedIdsWithoutAll };
    },
    querystringIds() {
      const ids = this.$route?.query[this.filter.id] || [];
      const idArray = Array.isArray(ids) ? ids : [ids];
      // If there were no querystring IDs, return the default options.
      if (!idArray.length) {
        return this.filter.defaultIds || [ALL];
      }

      return idArray;
    },
  },
  watch: {
    selectedIds(newIds, oldIds) {
      if (!isEqual(newIds, oldIds)) {
        console.log('selected IDs changed', newIds, oldIds);
        this.emitFilterChanged(this.filterObject);
        this.updateQuerystring();
      }
    },
    querystringIds: {
      immediate: true,
      handler() {
        this.selectedIds = this.querystringIds;
      },
    },
  },
  methods: {
    toggleOption({ id }) {
      console.log('toggle option', id);
      if (id === ALL) {
        // If we're toggling the All option, select just the All option.
        this.selectedIds = [ALL];
      } else {
        // Toggle whether the selected option is in the array or not.
        const ids = xor(this.selectedIdsWithoutAll, [id]);
        // If the last selected option is unselected, select the All option.
        this.selectedIds = ids.length ? ids : [ALL];
        console.log('setting selected IDs to', this.selectedIds);
      }
    },
    isSelected(option) {
      return this.selectedSet.has(option.id);
    },
    updateQuerystring() {
      if (this.$router && !isEqual(this.querystringIds, this.selectedIds)) {
        const query = { ...this.$route.query, [this.filter.id]: this.selectedIds };
        this.$router.push({ query });
      }
    },
    emitFilterChanged(data) {
      this.$emit('filter-changed', data);
    },
  },
};
</script>

<template>
  <filter-body v-model.trim="searchTerm" :name="filter.name" :selected-options="selectedOptions">
    <filter-item
      v-for="option in options"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`${filter.id}:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
