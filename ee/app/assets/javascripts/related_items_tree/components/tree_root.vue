<script>
export default {
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    children: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="list-unstyled related-items-list tree-root">
    <tree-item
      v-for="(item, index) in children"
      :key="index"
      :parent-item="parentItem"
      :item="item"
    />
  </ul>
</template>
