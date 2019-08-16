<script>
import { mapState, mapActions } from 'vuex';
import DateRangeDropdown from '../../shared/components/date_range_dropdown.vue';

export default {
  components: {
    DateRangeDropdown,
  },
  computed: {
    ...mapState('filters', ['groupNamespace', 'daysInPast']),
  },
  methods: {
    ...mapActions('filters', ['setDaysInPast']),
  },
};
</script>
<template>
  <div
    v-if="groupNamespace"
    class="dropdown-container d-flex flex-column flex-lg-row align-items-lg-center justify-content-lg-end"
  >
    <label class="mb-0 mr-1">{{ s__('Analytics|Timeframe') }}</label>
    <date-range-dropdown :default-selected="daysInPast" @selected="setDaysInPast" />
  </div>
</template>
