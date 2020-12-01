<script>
import ReportItemNamedList from './types/named_list.vue';

export default {
  name: 'ReportDetails',
  components: {
    ReportItemNamedList,
  },
  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },
  computed: {
    details() {
      return this.vulnerability.details;
    },
  },
};
</script>

<template>
  <div v-if="details" class="report-details-container">
    <report-item-named-list :items="details" :vuln="vulnerability" />
  </div>
</template>
