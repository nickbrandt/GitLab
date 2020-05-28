import { shallowMount } from '@vue/test-utils';

import AuditEventsApp from 'ee/audit_events/components/audit_events_app.vue';
import DateRangeField from 'ee/audit_events/components/date_range_field.vue';
import AuditEventsTable from 'ee/audit_events/components/audit_events_table.vue';
import AuditEventsFilter from 'ee/audit_events/components/audit_events_filter.vue';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';

describe('AuditEventsApp', () => {
  let wrapper;

  const events = [{ foo: 'bar' }];
  const enabledTokenTypes = AVAILABLE_TOKEN_TYPES;

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AuditEventsApp, {
      propsData: {
        formPath: 'form/path',
        isLastPage: true,
        dataQaSelector: 'qa_selector',
        enabledTokenTypes,
        events,
        ...props,
      },
      stubs: {
        AuditEventsFilter,
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
      expect(wrapper.find(AuditEventsTable).props('events')).toEqual(events);
    });

    it('passes its avilable token types to the logs filter', () => {
      expect(wrapper.find(AuditEventsFilter).props('enabledTokenTypes')).toEqual(enabledTokenTypes);
    });
  });
});
