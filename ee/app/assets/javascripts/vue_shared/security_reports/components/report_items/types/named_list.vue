<script>
import ReportDynType from '../dyn_type.vue';
import ReportLabel from '../label.vue';

export default {
  name: 'ReportItemNamedList',
  components: { ReportDynType, ReportLabel },
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
};
</script>

<template>
  <table class="table report-item-table">
    <tr v-for="(item, name) in items" class="report-item-table-tr">
      <td class="report-item-label-td report-item-table-td">
        <report-label v-bind="item" />
      </td>

      <td class="report-item-table-td">
        <report-dyn-type :vuln="vuln" :item="item" />
      </td>
    </tr>
  </table>
</template>
