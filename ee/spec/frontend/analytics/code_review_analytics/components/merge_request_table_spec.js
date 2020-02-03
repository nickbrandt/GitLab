import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlTable } from '@gitlab/ui';
import MergeRequestTable from 'ee/analytics/code_review_analytics/components/merge_request_table.vue';
import createState from 'ee/analytics/code_review_analytics/store/state';
import mergeRequests from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MergeRequestTable component', () => {
  let wrapper;
  let vuexStore;

  const createStore = (initialState = {}, getters = {}) =>
    new Vuex.Store({
      state: {
        ...createState(),
        ...initialState,
      },
      actions: {
        setProjectId: jest.fn(),
        setPage: jest.fn(),
        fetchMergeRequests: jest.fn(),
      },
      getters: {
        showMrCount: () => false,
        ...getters,
      },
    });

  const createComponent = store =>
    mount(MergeRequestTable, {
      localVue,
      store,
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findTable = () => wrapper.find(GlTable);

  describe('template', () => {
    beforeEach(() => {
      vuexStore = createStore({ mergeRequests });
      wrapper = createComponent(vuexStore);
    });

    it('renders the GlTable component', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the correct table headers', () => {
      const tableHeaders = [
        'Merge Request',
        'Review time',
        'Author',
        'Approvers',
        'Comments',
        'Commits',
        'Line changes',
      ];
      const headers = findTable().findAll('th');

      expect(headers.length).toBe(tableHeaders.length);

      tableHeaders.forEach((headerText, i) => expect(headers.at(i).text()).toEqual(headerText));
    });
  });

  describe('methods', () => {
    describe('formatReviewTime', () => {
      it('returns "days" when review time is >= 24', () => {
        expect(wrapper.vm.formatReviewTime(51)).toBe('2 days');
      });

      it('returns "hours" when review time is < 18', () => {
        expect(wrapper.vm.formatReviewTime(18)).toBe('18 hours');
      });

      it('returns "< 1 hour" when review is < 1', () => {
        expect(wrapper.vm.formatReviewTime(0)).toBe('< 1 hour');
      });
    });
  });
});
