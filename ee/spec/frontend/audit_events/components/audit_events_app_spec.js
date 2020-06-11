import { shallowMount } from '@vue/test-utils';

import AuditEventsApp from 'ee/audit_events/components/audit_events_app.vue';
import DateRangeField from 'ee/audit_events/components/date_range_field.vue';
import SortingField from 'ee/audit_events/components/sorting_field.vue';
import AuditEventsTable from 'ee/audit_events/components/audit_events_table.vue';
import AuditEventsFilter from 'ee/audit_events/components/audit_events_filter.vue';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';
import createStore from 'ee/audit_events/store';

describe('AuditEventsApp', () => {
  let wrapper;
  let store;

  const events = [{ foo: 'bar' }];
  const enabledTokenTypes = AVAILABLE_TOKEN_TYPES;
  const filterQaSelector = 'filter_qa_selector';
  const tableQaSelector = 'table_qa_selector';

  const initComponent = (props = {}) => {
    store = createStore();
    wrapper = shallowMount(AuditEventsApp, {
      store,
      propsData: {
        isLastPage: true,
        filterQaSelector,
        tableQaSelector,
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
    store = null;
  });

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('passes its events property to the logs table', () => {
      expect(wrapper.find(AuditEventsTable).props('events')).toEqual(events);
    });

    it('passes the tables QA selector to the logs table', () => {
      expect(wrapper.find(AuditEventsTable).props('qaSelector')).toEqual(tableQaSelector);
    });

    it('passes its available token types to the logs filter', () => {
      expect(wrapper.find(AuditEventsFilter).props('enabledTokenTypes')).toEqual(enabledTokenTypes);
    });

    it('passes the filters QA selector to the logs filter', () => {
      expect(wrapper.find(AuditEventsFilter).props('qaSelector')).toEqual(filterQaSelector);
    });

    it('sets the defaultSelectedToken of the logs filter', () => {
      expect(wrapper.find(AuditEventsFilter).props('defaultSelectedToken')).toEqual(
        store.state.filterValue,
      );
    });

    it('sets the dates of the date range field', () => {
      const { startDate, endDate } = store.state;
      expect(wrapper.find(DateRangeField).props('startDate')).toEqual(startDate);
      expect(wrapper.find(DateRangeField).props('endDate')).toEqual(endDate);
    });

    it('sets the sort order of the sorting field', () => {
      expect(wrapper.find(SortingField).props('sortBy')).toEqual(store.state.sortBy);
    });
  });

  describe('when a field is selected', () => {
    beforeEach(() => {
      initComponent();
    });

    it.each`
      name               | field                | handler
      ${'date range'}    | ${DateRangeField}    | ${'setDateRange'}
      ${'sort by'}       | ${SortingField}      | ${'setSortBy'}
      ${'events filter'} | ${AuditEventsFilter} | ${'setFilterValue'}
    `('for $name, it calls $handler', ({ field, handler }) => {
      const stub = jest.fn();
      wrapper.setMethods({ [handler]: stub });
      wrapper.find(field).vm.$emit('selected');
      expect(stub).toHaveBeenCalled();
    });
  });
});
