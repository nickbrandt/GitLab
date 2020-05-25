import { shallowMount } from '@vue/test-utils';

import AuditLogApp from 'ee/audit_logs/components/audit_log_app.vue';
import DateRangeField from 'ee/audit_logs/components/date_range_field.vue';
import LogsTable from 'ee/audit_logs/components/logs_table.vue';

describe('AuditLogApp', () => {
  let wrapper;

  const events = [{ foo: 'bar' }];

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AuditLogApp, {
      propsData: {
        formPath: 'form/path',
        isLastPage: true,
        dataQaSelector: 'qa_selector',
        events,
        ...props,
      },
      stubs: {
        AuditLogFilter: {
          template: `<div class="audit-log-filter"></div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('sets the form element on the date range field', () => {
      const { element } = wrapper.find('form');
      expect(wrapper.find(DateRangeField).props('formElement')).toEqual(element);
    });

    it('passes its events property to the logs table', () => {
      expect(wrapper.find(LogsTable).props('events')).toEqual(events);
    });
  });
});
