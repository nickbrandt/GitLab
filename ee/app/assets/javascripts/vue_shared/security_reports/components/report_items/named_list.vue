<script>
import ReportLabel from './label.vue';
import ReportItemText from './text.vue';
import ReportItemList from './list.vue';
import ReportItemInt from './int.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemCode from './code.vue';
import ReportItemUrl from './url.vue';
import ReportItemCommit from './commit.vue';

export default {
  name: 'ReportItemNamedList',
  components: {
    ReportLabel,
    ReportItemList,
    ReportItemText,
    ReportItemModuleLocation,
    ReportItemFileLocation,
    ReportItemInt,
    ReportItemCode,
    ReportItemUrl,
    ReportItemCommit
  },
  props: {
    items: {
      type: Object,
      required: true,
    },
    vuln: {
      type: Object,
      required: true,
    }
  },
  computed: {
  },
  beforeCreate() {
    this.$options.components.ReportItemList = require('./list.vue').default;
    this.$options.components.ReportItemTable = require('./table.vue').default;
  },
};
</script>

<template>
  <table class="table report-item-table">
    <tr v-for="(item, name) in items" class="report-item-table-tr">
      <td class="report-item-label-td report-item-table-td">
        <report-label v-bind="item" />
      </td>

      <td class="report-item-table-td">
        <component
          :is="'report-item-' + item.type"
          v-bind="item"
          :vuln="vuln"
        />
      </td>
    </tr>
  </table>
</template>
