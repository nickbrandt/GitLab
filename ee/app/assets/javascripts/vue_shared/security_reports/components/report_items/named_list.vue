<script>
import ReportItemLabel from './label.vue';
import ReportItemText from './text.vue';
import ReportItemList from './list.vue';
import ReportItemHexInt from './hex_int.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemCode from './code.vue';
import ReportItemLink from './link.vue';

export default {
  name: 'ReportItemNamedList',
  components: {
    ReportItemLabel,
    ReportItemList,
    ReportItemText,
    ReportItemModuleLocation,
    ReportItemFileLocation,
    ReportItemHexInt,
    ReportItemCode,
    ReportItemLink
  },
  props: {
    items: {
      type: Object,
      required: true
    }
  },
  computed: {
  },
  beforeCreate() {
    this.$options.components.ReportItemList = require('./list.vue').default;
  },
};
</script>

<template>
  <table class="table report-item-table">
    <tr v-for="(item, name) in items">
      <td class="report-item-label-td">
        <report-item-label v-bind="item" />
      </td>

      <td>
        <component
          :is="'report-item-' + item.type"
          v-bind="item"
        />
      </td>
    </tr>
  </table>
</template>
