import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon, GlBadge, GlPagination } from '@gitlab/ui';
import CodeReviewAnalyticsApp from 'ee/analytics/code_review_analytics/components/app.vue';
import MergeRequestTable from 'ee/analytics/code_review_analytics/components/merge_request_table.vue';
import createState from 'ee/analytics/code_review_analytics/store/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('CodeReviewAnalyticsApp component', () => {
  let wrapper;
  let vuexStore;

  let setPage;
  let fetchMergeRequests;

  const pageInfo = {
    page: 1,
    perPage: 10,
    total: 50,
  };

  const createStore = (initialState = {}, getters = {}) =>
    new Vuex.Store({
      state: {
        ...createState(),
        ...initialState,
      },
      actions: {
        setProjectId: jest.fn(),
        setPage,
        fetchMergeRequests,
      },
      getters: {
        showMrCount: () => false,
        ...getters,
      },
    });

  const createComponent = store =>
    shallowMount(CodeReviewAnalyticsApp, {
      localVue,
      store,
      propsData: {
        projectId: 1,
      },
    });

  beforeEach(() => {
    setPage = jest.fn();
    fetchMergeRequests = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findBadge = () => wrapper.find(GlBadge);
  const findMrTable = () => wrapper.find(MergeRequestTable);
  const findPagination = () => wrapper.find(GlPagination);

  describe('template', () => {
    describe('while loading', () => {
      beforeEach(() => {
        vuexStore = createStore({ isLoading: true });
        wrapper = createComponent(vuexStore);
      });

      it('should display a loading indicator', () => {
        expect(findLoadingIcon().isVisible()).toBe(true);
      });

      it('should not show the badge containing the MR count', () => {
        expect(findBadge().isVisible()).toBe(false);
      });

      it('should not render the merge requests table', () => {
        expect(findMrTable().exists()).toBe(false);
      });

      it('should not render the pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when finished loading', () => {
      beforeEach(() => {
        vuexStore = createStore({ isLoading: false, pageInfo }, { showMrCount: () => true });
        wrapper = createComponent(vuexStore);
      });

      it('should hide the loading indicator', () => {
        expect(findLoadingIcon().isVisible()).toBe(false);
      });

      it('should show the badge containing the MR count', () => {
        expect(findBadge().isVisible()).toBe(true);
        expect(findBadge().text()).toEqual(`${50}`);
      });

      it('should render the merge requests table', () => {
        expect(findMrTable().exists()).toBe(true);
      });

      it('should render the pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });
    });
  });

  describe('changing the page', () => {
    beforeEach(() => {
      vuexStore = createStore({ isLoading: false, pageInfo }, { showMrCount: () => true });
      wrapper = createComponent(vuexStore);
      wrapper.vm.currentPage = 2;
    });

    it('should call the setPage action', () => {
      expect(setPage).toHaveBeenCalledWith(expect.anything(), 2, undefined);
    });

    it('should call fetchMergeRequests action', () => {
      expect(fetchMergeRequests).toHaveBeenCalled();
    });
  });
});
