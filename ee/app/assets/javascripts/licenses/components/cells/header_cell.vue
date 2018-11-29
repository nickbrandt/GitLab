<script>
import Icon from '~/vue_shared/components/icon.vue';
import Cell from './cell.vue';

export default {
  name: 'HeaderCell',
  components: {
    Icon,
    Cell,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <cell class="license-header-cell" :is-flexible="false">
    <template slot="title">
      <icon class="icon" :name="icon" />
      <span class="ml-2 font-weight-bold">{{ title }}</span>
    </template>
  </cell>
</template>
