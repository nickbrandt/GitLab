<script>
import ReportDynType from '../dyn_type.vue';

export default {
  name: 'ReportItemList',
  components: { ReportDynType },
  props: {
    items: {
      type: Array,
      required: true,
    },
    vuln: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div v-for="item in items">
      <report-dyn-type v-bind="item" :vuln="vuln" :item="item" />
    </div>
  </div>
</template>
