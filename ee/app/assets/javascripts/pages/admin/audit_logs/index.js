import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import AuditLogApp from 'ee/audit_logs/components/audit_log_app.vue';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#js-audit-log-app');
  const { events, isLastPage, formPath, enabledTokenTypes } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'AuditLogApp',
    render: createElement =>
      createElement(AuditLogApp, {
        props: {
          events: JSON.parse(events),
          isLastPage: parseBoolean(isLastPage),
          enabledTokenTypes: JSON.parse(enabledTokenTypes),
          formPath,
        },
      }),
  });
});
