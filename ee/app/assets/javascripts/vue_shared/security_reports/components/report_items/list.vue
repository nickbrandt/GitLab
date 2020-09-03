<script>
import ReportItemText from './text.vue';
import ReportItemNamedList from './named_list.vue';
import ReportItemModuleLocation from './module_location.vue';
import ReportItemFileLocation from './file_location.vue';
import ReportItemInt from './int.vue';
import ReportItemCode from './code.vue';
import ReportItemUrl from './url.vue';
import ReportItemTable from './table.vue';
import ReportItemCommit from './commit.vue';

export default {
  name: 'ReportItemList',
  components: {
    ReportItemText,
    ReportItemNamedList,
    ReportItemModuleLocation,
    ReportItemInt,
    ReportItemCode, 
    ReportItemFileLocation,
    ReportItemUrl,
    ReportItemTable,
    ReportItemCommit
  },
  props: {
    items: {
      type: Array,
      required: true
    },
    vuln: {
      type: Object,
      required: true,
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
      :vuln="vuln"
    />
  </table>
</template>
