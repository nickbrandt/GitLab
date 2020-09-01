<script>
import ReportItemLabel from './label.vue';
import ReportItemNamedList from './named_list.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemHexInt from './hex_int.vue';
import ReportItemCode from './code.vue';
import ReportItemPlain from './plain.vue';
import ReportItemLink from './link.vue';

export default {
  name: 'ReportItemList',
  components: {
    ReportItemLabel,
    ReportItemNamedList,
    ReportItemModuleLocation,
    ReportItemHexInt,
    ReportItemCode, 
    ReportItemFileLocation,
    ReportItemPlain,
    ReportItemLink
  },
  props: {
    items: {
      type: Array,
      required: true
    }
  },
  computed: {
  },
};
</script>

<template>
  <table class="table report-item-table">
    <component
      v-for="item in items"
      :is="'report-item-' + item.type"
      v-if="item.type"
      v-bind="item"
    />
  </table>
</template>
