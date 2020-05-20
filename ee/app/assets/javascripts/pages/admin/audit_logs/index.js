import Vue from 'vue';

import { parseBoolean } from '~/lib/utils/common_utils';

import AuditLogFilter from 'ee/audit_logs/components/audit_log_filter.vue';
import DateRangeField from 'ee/audit_logs/components/date_range_field.vue';
import SortingField from 'ee/audit_logs/components/sorting_field.vue';
import LogsTable from 'ee/audit_logs/components/logs_table.vue';

// Merge these when working on https://gitlab.com/gitlab-org/gitlab/-/issues/215363
document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#js-audit-logs-filter-app');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'AuditLogFilterApp',
    render: createElement => createElement(AuditLogFilter),
  });
});
document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#js-audit-logs-date-range-app');
  const formElement = el.closest('form');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'AuditLogsDateRangeApp',
    render: createElement =>
      createElement(DateRangeField, {
        props: {
          ...el.dataset,
          formElement,
        },
      }),
  });
});
document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#js-audit-logs-sorting-app');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'AuditLogSortingApp',
    render: createElement => createElement(SortingField),
  });
});
document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#js-audit-logs-table-app');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'AuditLogsTableApp',
    render: createElement =>
      createElement(LogsTable, {
        props: {
          events: JSON.parse(el.dataset.events),
          isLastPage: parseBoolean(el.dataset.isLastPage),
        },
      }),
  });
});
