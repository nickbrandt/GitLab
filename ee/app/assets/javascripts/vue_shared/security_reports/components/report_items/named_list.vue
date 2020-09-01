<script>
import ReportItemLabel from './label.vue';
import ReportItemList from './list.vue';
import ReportItemHexInt from './hex_int.vue';
import ReportItemPlain from './plain.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemCode from './code.vue';
import ReportItemLabelValue from './label_value.vue';
import ReportItemLink from './link.vue';

export default {
  name: 'ReportItemNamedList',
  components: {
    ReportItemList,
    ReportItemLabel,
    ReportItemModuleLocation,
    ReportItemFileLocation,
    ReportItemHexInt,
    ReportItemPlain,
    ReportItemCode,
    ReportItemLabelValue,
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
          <label class="font-weight-bold">{{name}}</label>
      </td>

      <td v-if="item.type == 'label'">
        <report-item-label-value :value="item.value" />
      </td>

      <td v-else>
        <component
          :is="'report-item-' + item.type"
          v-bind="item"
        />
      </td>
    </tr>
  </table>
</template>
