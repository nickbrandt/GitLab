<script>
import AuditLogFilter from './audit_log_filter.vue';
import DateRangeField from './date_range_field.vue';
import SortingField from './sorting_field.vue';
import LogsTable from './logs_table.vue';

export default {
  components: {
    AuditLogFilter,
    DateRangeField,
    SortingField,
    LogsTable,
  },
  props: {
    formPath: {
      type: String,
      required: true,
    },
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
  },
  data() {
    return {
      formElement: null,
    };
  },
  mounted() {
    // Passing the form to child components is only temporary
    // and should be changed when this issue is completed:
    // https://gitlab.com/gitlab-org/gitlab/-/issues/217759
    this.formElement = this.$refs.form;
  },
};
</script>

<template>
  <div>
    <div class="row-content-block second-block pb-0">
      <form
        ref="form"
        method="GET"
        :path="formPath"
        class="filter-form d-flex justify-content-between audit-controls row"
      >
        <div class="col-lg-auto flex-fill form-group align-items-lg-center pr-lg-8">
          <AuditLogFilter v-bind="{ enabledTokenTypes }" />
        </div>
        <div class="d-flex col-lg-auto flex-wrap pl-lg-0">
          <div
            class="audit-controls d-flex align-items-lg-center flex-column flex-lg-row col-lg-auto px-0"
          >
            <DateRangeField v-if="formElement" :form-element="formElement" />
            <SortingField />
          </div>
        </div>
      </form>
    </div>
    <LogsTable v-bind="{ events, isLastPage }" />
  </div>
</template>
