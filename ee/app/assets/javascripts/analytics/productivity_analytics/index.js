import Vue from 'vue';
import { mapState, mapActions } from 'vuex';
import { defaultDaysInPast } from './constants';
import store from './store';
import FilterDropdowns from './components/filter_dropdowns.vue';
import DateRange from '../shared/components/daterange.vue';
import ProductivityAnalyticsApp from './components/app.vue';
import FilteredSearchProductivityAnalytics from './filtered_search_productivity_analytics';
import { getLabelsEndpoint, getMilestonesEndpoint, getDefaultStartDate } from './utils';

export default () => {
  const container = document.getElementById('js-productivity-analytics');
  const groupProjectSelectContainer = container.querySelector('.js-group-project-select-container');
  const searchBarContainer = container.querySelector('.js-search-bar');

  // we need to store the HTML content so we can reset it later
  const issueFilterHtml = searchBarContainer.querySelector('.issues-filters').innerHTML;
  const timeframeContainer = container.querySelector('.js-timeframe-container');
  const appContainer = container.querySelector('.js-productivity-analytics-app-container');

  const { endpoint, emptyStateSvgPath, noAccessSvgPath } = appContainer.dataset;
  const { startDate: computedStartDate } = timeframeContainer.dataset;

  const minDate = computedStartDate ? new Date(computedStartDate) : null;
  const mergedAtAfter = getDefaultStartDate(minDate, defaultDaysInPast);
  const mergedAtBefore = new Date(Date.now());

  const initialData = {
    mergedAtAfter,
    mergedAtBefore,
  };

  let filterManager;

  // eslint-disable-next-line no-new
  new Vue({
    el: groupProjectSelectContainer,
    store,
    created() {
      this.setEndpoint(endpoint);

      // let's not fetch data since we might not have a groupNamespace selected yet
      // this just populates the store with the initial data and waits for a groupNamespace to be set
      this.setInitialData({ skipFetch: true, data: initialData });
    },
    methods: {
      ...mapActions(['setEndpoint']),
      ...mapActions('filters', ['setInitialData']),
      onGroupSelected({ groupNamespace, groupId }) {
        this.initFilteredSearch({ groupNamespace, groupId });
      },
      onProjectSelected({ groupNamespace, groupId, projectNamespace, projectId }) {
        this.initFilteredSearch({ groupNamespace, groupId, projectNamespace, projectId });
      },
      initFilteredSearch({ groupNamespace, groupId, projectNamespace = '', projectId = null }) {
        // let's unbind attached event handlers first and reset the template
        if (filterManager) {
          filterManager.cleanup();
          searchBarContainer.innerHTML = issueFilterHtml;
        }

        searchBarContainer.classList.remove('hide');

        const filteredSearchInput = searchBarContainer.querySelector('.filtered-search');
        const labelsEndpoint = getLabelsEndpoint(groupNamespace, projectNamespace);
        const milestonesEndpoint = getMilestonesEndpoint(groupNamespace, projectNamespace);

        filteredSearchInput.setAttribute('data-group-id', groupId);

        if (projectId) {
          filteredSearchInput.setAttribute('data-project-id', projectId);
        }

        filteredSearchInput.setAttribute('data-labels-endpoint', labelsEndpoint);
        filteredSearchInput.setAttribute('data-milestones-endpoint', milestonesEndpoint);
        filterManager = new FilteredSearchProductivityAnalytics({ isGroup: false });
        filterManager.setup();
      },
    },
    render(h) {
      return h(FilterDropdowns, {
        on: {
          groupSelected: this.onGroupSelected,
          projectSelected: this.onProjectSelected,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: timeframeContainer,
    store,
    computed: {
      ...mapState('filters', ['groupNamespace', 'startDate', 'endDate']),
    },
    methods: {
      ...mapActions('filters', ['setDateRange']),
      onDateRangeChange({ startDate, endDate }) {
        this.setDateRange({ startDate, endDate });
      },
    },
    render(h) {
      return h(DateRange, {
        props: {
          show: this.groupNamespace !== null,
          startDate: mergedAtAfter,
          endDate: mergedAtBefore,
          minDate,
        },
        on: {
          change: this.onDateRangeChange,
        },
      });
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: appContainer,
    store,
    render(h) {
      return h(ProductivityAnalyticsApp, {
        props: {
          emptyStateSvgPath,
          noAccessSvgPath,
        },
      });
    },
  });
};
