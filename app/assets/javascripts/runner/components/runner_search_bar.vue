<script>
import { __ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  components: {
    FilteredSearchBar,
  },
  data() {
    const sortOptions = [
      {
        id: 1,
        title: __('Created date'),
        sortDirection: {
          descending: 'created_desc',
          ascending: 'created_asc',
        },
      },
      {
        id: 2,
        title: __('Last contact'),
        sortDirection: {
          descending: 'updated_desc',
          ascending: 'updated_asc',
        },
      },
    ];

    return {
      searchTokens: [],
      searchSortOptions: sortOptions,
      searchInitialSortBy: sortOptions[0].sortDirection.descending,
    };
  },
};
</script>

<template>
  <filtered-search-bar
    v-bind="$attrs"
    recent-searches-storage-key="runners"
    :sort-options="searchSortOptions"
    :initial-sort-by="searchInitialSortBy"
    :tokens="searchTokens"
    :search-input-placeholder="__('Search or filter results...')"
    v-on="$listeners"
  />
</template>
