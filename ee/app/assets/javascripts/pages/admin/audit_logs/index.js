import Vue from 'vue';

import DateRangeField from './components/date_range_field.vue';
import AuditLogs from './audit_logs';

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
