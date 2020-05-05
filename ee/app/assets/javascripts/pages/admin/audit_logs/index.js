import Vue from 'vue';

import { parseBoolean } from '~/lib/utils/common_utils';

import DateRangeField from 'ee/audit_logs/components/date_range_field.vue';
import LogsTable from 'ee/audit_logs/components/logs_table.vue';

import AuditLogs from './audit_logs';

// Merge these when working on https://gitlab.com/gitlab-org/gitlab/-/issues/215363
document.addEventListener('DOMContentLoaded', () => new AuditLogs());
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
