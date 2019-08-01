import Vue from 'vue';
import Api from '~/api';
import store from './store';
import FilterDropdowns from './components/filter_dropdowns.vue';
import TimeFrameDropdown from './components/timeframe_dropdown.vue';
import ProductivityAnalyticsApp from './components/app.vue';
import FilteredSearchProductivityAnalytics from './filtered_search_productivity_analytics';

export default () => {
  const container = document.getElementById('js-productivity-analytics');
  const groupProjectSelectContainer = container.querySelector('.js-group-project-select-container');
  const searchBarContainer = container.querySelector('.js-search-bar');

  // we need to store the HTML content so we can reset it later
  const issueFilterHtml = searchBarContainer.querySelector('.issues-filters').innerHTML;
  const timeframeContainer = container.querySelector('.js-timeframe-container');
  const appContainer = container.querySelector('.js-productivity-analytics-app-container');

  let filterManager;

  // eslint-disable-next-line no-new
  new Vue({
    el: groupProjectSelectContainer,
    store,
    methods: {
      onGroupSelected(namespacePath) {
        this.initFilteredSearch(namespacePath);
      },
      onProjectSelected({ namespacePath, project }) {
        this.initFilteredSearch(namespacePath, project);
      },
      initFilteredSearch(namespacePath, project = '') {
        // let's unbind attached event handlers first and reset the template
        if (filterManager) {
          filterManager.cleanup();
          searchBarContainer.innerHTML = issueFilterHtml;
        }

        searchBarContainer.classList.remove('hide');

        const filteredSearchInput = searchBarContainer.querySelector('.filtered-search');
        const labelsEndpoint = this.getLabelsEndpoint(namespacePath, project);
        const milestonesEndpoint = this.getMilestonesEndpoint(namespacePath, project);

        filteredSearchInput.setAttribute('data-group-id', namespacePath);

        if (project) {
          filteredSearchInput.setAttribute('data-project-id', project);
        }

        filteredSearchInput.setAttribute('data-labels-endpoint', labelsEndpoint);
        filteredSearchInput.setAttribute('data-milestones-endpoint', milestonesEndpoint);
        filterManager = new FilteredSearchProductivityAnalytics({ isGroup: false });
        filterManager.setup();
      },
      getLabelsEndpoint(namespacePath, projectPath) {
        if (projectPath) {
          return Api.buildUrl(Api.projectLabelsPath)
            .replace(':namespace_path', namespacePath)
            .replace(':project_path', projectPath);
        }

        return Api.buildUrl(Api.groupLabelsPath).replace(':namespace_path', namespacePath);
      },
      getMilestonesEndpoint(namespacePath, projectPath) {
        if (projectPath) {
          return `/${namespacePath}/${projectPath}/-/milestones`;
        }

        return `/groups/${namespacePath}/-/milestones`;
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
    render(h) {
      return h(TimeFrameDropdown, {});
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: appContainer,
    store,
    render(h) {
      return h(ProductivityAnalyticsApp, {});
    },
  });
};
