<script>
import { mapActions, mapState } from 'vuex';
import AuditEventsFilter from './audit_events_filter.vue';
import DateRangeField from './date_range_field.vue';
import SortingField from './sorting_field.vue';
import AuditEventsTable from './audit_events_table.vue';

export default {
  components: {
    AuditEventsFilter,
    DateRangeField,
    SortingField,
    AuditEventsTable,
  },
  props: {
    events: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLastPage: {
      type: Boolean,
      required: false,
      default: false,
    },
    enabledTokenTypes: {
      type: Array,
      required: true,
    },
    filterQaSelector: {
      type: String,
      required: false,
      default: undefined,
    },
    tableQaSelector: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    ...mapState(['filterValue', 'startDate', 'endDate', 'sortBy']),
  },
  methods: {
    ...mapActions(['setDateRange', 'setFilterValue', 'setSortBy']),
  },
};
</script>

<template>
  <div>
    <div class="row-content-block second-block pb-0">
      <div class="d-flex justify-content-between audit-controls row">
        <div class="col-lg-auto flex-fill form-group align-items-lg-center pr-lg-8">
          <audit-events-filter
            v-bind="{
              enabledTokenTypes,
              qaSelector: filterQaSelector,
              defaultSelectedToken: filterValue,
            }"
            @selected="setFilterValue"
          />
        </div>
        <div class="d-flex col-lg-auto flex-wrap pl-lg-0">
          <div
            class="audit-controls d-flex align-items-lg-center flex-column flex-lg-row col-lg-auto px-0"
          >
            <date-range-field v-bind="{ startDate, endDate }" @selected="setDateRange" />
            <sorting-field v-bind="{ sortBy }" @selected="setSortBy" />
          </div>
        </div>
      </div>
    </div>
    <audit-events-table v-bind="{ events, isLastPage, qaSelector: tableQaSelector }" />
  </div>
</template>
