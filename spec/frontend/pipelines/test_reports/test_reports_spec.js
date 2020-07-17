import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { getJSONFixture } from 'helpers/fixtures';
import TestReports from '~/pipelines/components/test_reports/test_reports.vue';
import TestSummary from '~/pipelines/components/test_reports/test_summary.vue';
import TestSummaryTable from '~/pipelines/components/test_reports/test_summary_table.vue';
import * as getters from '~/pipelines/stores/test_reports/getters';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Test reports app', () => {
  let wrapper;
  let store;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const loadingSpinner = () => wrapper.find('.js-loading-spinner');
  const testsDetail = () => wrapper.find('.js-tests-detail');
  const noTestsToShow = () => wrapper.find('.js-no-tests-to-show');
  const testSummary = () => wrapper.find(TestSummary);
  const testSummaryTable = () => wrapper.find(TestSummaryTable);

  const actionSpies = {
    fetchTestSuite: jest.fn(),
    fetchSummary: jest.fn(),
    setSelectedSuiteIndex: jest.fn(),
    removeSelectedSuiteIndex: jest.fn(),
  };

  const createComponent = (state = {}) => {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        selectedSuiteIndex: null,
        testReports,
        ...state,
      },
      actions: actionSpies,
      getters,
    });

    wrapper = shallowMount(TestReports, {
      store,
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when component is created', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should call fetchSummary', () => {
      expect(actionSpies.fetchSummary).toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => createComponent({ isLoading: true }));

    it('shows the loading spinner', () => {
      expect(noTestsToShow().exists()).toBe(false);
      expect(testsDetail().exists()).toBe(false);
      expect(loadingSpinner().exists()).toBe(true);
    });
  });

  describe('when the api returns no data', () => {
    beforeEach(() => createComponent({ testReports: {} }));

    it('displays that there are no tests to show', () => {
      const noTests = noTestsToShow();

      expect(noTests.exists()).toBe(true);
      expect(noTests.text()).toBe('There are no tests to show.');
    });
  });

  describe('when the api returns data', () => {
    beforeEach(() => createComponent());

    it('sets testReports and shows tests', () => {
      expect(wrapper.vm.testReports).toBeTruthy();
      expect(wrapper.vm.showTests).toBeTruthy();
    });
  });

  describe('when a suite is clicked', () => {
    describe('when the full test report has already been received', () => {
      beforeEach(() => {
        createComponent({ hasFullReport: true });
        testSummaryTable().vm.$emit('row-click', 0);
      });

      it('should only call setSelectedSuiteIndex', () => {
        expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalled();
        expect(actionSpies.fetchTestSuite).not.toHaveBeenCalled();
      });
    });

    describe('when the full test report has not been received', () => {
      describe('when the full suite has already been received', () => {
        beforeEach(() => {
          const mockState = { hasFullReport: false, testReports };
          mockState.testReports.test_suites[0].hasFullSuite = true;
          createComponent(mockState);
          testSummaryTable().vm.$emit('row-click', 0);
        });

        it('should only call setSelectedSuiteIndex', () => {
          expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalled();
          expect(actionSpies.fetchTestSuite).not.toHaveBeenCalled();
        });
      });

      describe('when the full suite has not been received', () => {
        beforeEach(() => {
          const mockState = { hasFullReport: false, testReports };
          mockState.testReports.test_suites[0].hasFullSuite = false;
          createComponent(mockState);
          testSummaryTable().vm.$emit('row-click', 0);
        });

        it('should call setSelectedSuiteIndex and fetchTestSuite', () => {
          expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalled();
          expect(actionSpies.fetchTestSuite).toHaveBeenCalled();
        });
      });
    });
  });

  describe('when clicking back to summary', () => {
    beforeEach(() => {
      createComponent({ selectedSuiteIndex: 0 });
      testSummary().vm.$emit('on-back-click');
    });

    it('should call removeSelectedSuiteIndex', () => {
      expect(actionSpies.removeSelectedSuiteIndex).toHaveBeenCalled();
    });
  });
});
