<script>
import ReportDynType from '../dyn_type.vue';

export default {
  name: 'ReportItemTable',
  components: { ReportDynType },
  props: {
    header: {
      type: Array,
      required: false,
      default: () => [],
    },
    rows: {
      type: Array,
      required: false,
      default: () => [],
    },
    vuln: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <table class="table report-item-data-table">
    <tr v-if="header">
      <th v-for="heading in header" class="report-item-data-table-th">
        <report-dyn-type :vuln="vuln" :item="heading" />
      </th>
    </tr>

    <tr v-for="row in rows">
      <td v-for="cell in row" class="report-item-data-table-td">
        <report-dyn-type :vuln="vuln" :item="cell" />
      </td>
    </tr>
  </table>
</template>
