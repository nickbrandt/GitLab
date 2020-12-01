<script>
import ReportItemLabel from './label.vue';
import ReportItemText from './text.vue';
import ReportItemList from './list.vue';
import ReportItemInt from './int.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemCode from './code.vue';
import ReportItemUrl from './url.vue';
import ReportItemCommit from './commit.vue';

export default {
  name: 'ReportItemTable',
  components: {
    ReportItemLabel,
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
    header: {
      type: Array,
      required: false,
      default: ()=> [],
    },
    rows: {
      type: Array,
      required: false,
      default: ()=> [],
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
  },
};
</script>

<template>
  <table class="table report-item-data-table">
    <tr v-if="header">
      <th v-for="heading in header" class="report-item-data-table-th">
        <component
          :is="'report-item-' + heading.type"
          v-bind="heading"
          :vuln="vuln"
        />
      </th>
    </tr>

    <tr v-for="row in rows">
      <td v-for="cell in row" class="report-item-data-table-td">
        <component
          :is="'report-item-' + cell.type"
          v-bind="cell"
          :vuln="vuln"
        />
      </td>
    </tr>
  </table>
</template>
