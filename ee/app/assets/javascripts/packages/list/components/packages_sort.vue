<script>
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import {
  LIST_KEY_PROJECT,
  ASCENDING_ODER,
  DESCENDING_ORDER,
  TABLE_HEADER_FIELDS,
} from '../constants';
import { mapState, mapActions } from 'vuex';

export default {
  name: 'PackageSort',
  components: {
    GlSorting,
    GlSortingItem,
  },
  computed: {
    ...mapState({
      isGroupPage: state => state.config.isGroupPage,
      orderBy: state => state.sorting.orderBy,
      sort: state => state.sorting.sort,
    }),
    sortText() {
      const field = this.sortableFields.find(s => s.orderBy === this.orderBy);
      return field ? field.label : '';
    },
    sortableFields() {
      // This list is filtered in the case of the project page, and the project column is removed
      return TABLE_HEADER_FIELDS.filter(f => f.key !== LIST_KEY_PROJECT || this.isGroupPage);
    },
    isSortAscending() {
      return this.sort === ASCENDING_ODER;
    },
  },
  methods: {
    ...mapActions(['setSorting']),
    onDirectionChange() {
      const sort = this.isSortAscending ? DESCENDING_ORDER : ASCENDING_ODER;
      this.setSorting({ sort });
      this.$emit('sort:changed');
    },
    onSortItemClick(item) {
      this.setSorting({ orderBy: item });
      this.$emit('sort:changed');
    },
  },
};
</script>

<template>
  <gl-sorting
    :text="sortText"
    :is-ascending="isSortAscending"
    @sortDirectionChange="onDirectionChange"
  >
    <gl-sorting-item
      v-for="item in sortableFields"
      ref="packageListSortItem"
      :key="item.key"
      @click="onSortItemClick(item.orderBy)"
    >
      {{ item.label }}
    </gl-sorting-item>
  </gl-sorting>
</template>
