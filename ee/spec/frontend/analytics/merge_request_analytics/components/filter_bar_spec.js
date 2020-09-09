import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import storeConfig from 'ee/analytics/merge_request_analytics/store';
import FilterBar from 'ee/analytics/merge_request_analytics/components/filter_bar.vue';
import initialFiltersState from 'ee/analytics/shared/store/modules/filters/state';
import * as utils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import {
  filterMilestones,
  filterLabels,
  filterUsers,
} from '../../shared/store/modules/filters/mock_data';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import { ITEM_TYPE } from '~/groups/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

const milestoneTokenType = 'milestone';
const labelsTokenType = 'labels';
const authorTokenType = 'author';
const assigneeTokenType = 'assignee';

const initialFilterBarState = {
  selectedMilestone: null,
  selectedAuthor: null,
  selectedAssignee: null,
  selectedLabelList: null,
};

const defaultParams = {
  milestone_title: null,
  'not[milestone_title]': null,
  author_username: null,
  'not[author_username]': null,
  assignee_username: null,
  'not[assignee_username]': null,
  label_name: null,
  'not[label_name]': null,
};

async function shouldMergeUrlParams(wrapper, result) {
  await wrapper.vm.$nextTick();
  expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(result, window.location.href, {
    spreadArrays: true,
  });
  expect(commonUtils.historyPushState).toHaveBeenCalled();
}

function getFilterParams(tokens, options = {}) {
  const { key = 'value', operator = '=', prop = 'title' } = options;
  return tokens.map(token => {
    return { [key]: token[prop], operator };
  });
}

function getFilterValues(tokens, options = {}) {
  const { prop = 'title' } = options;
  return tokens.map(token => token[prop]);
}

const selectedMilestoneParams = getFilterParams(filterMilestones);
const selectedLabelParams = getFilterParams(filterLabels);
const selectedUserParams = getFilterParams(filterUsers, { prop: 'name' });

const milestoneValues = getFilterValues(filterMilestones);
const labelValues = getFilterValues(filterLabels);
const userValues = getFilterValues(filterUsers, { prop: 'name' });

describe('Filter bar', () => {
  let wrapper;
  let vuexStore;
  let mock;

  let setFiltersMock;

  const createStore = (initialState = {}) => {
    setFiltersMock = jest.fn();

    return new Vuex.Store({
      modules: {
        filters: {
          namespaced: true,
          state: {
            ...initialFiltersState(),
            ...initialState,
          },
          actions: {
            setFilters: setFiltersMock,
          },
        },
      },
    });
  };

  function createComponent(initialStore, options = {}) {
    const { type = ITEM_TYPE.PROJECT } = options;
    return shallowMount(FilterBar, {
      localVue,
      store: initialStore,
      provide: () => ({
        fullPath: 'foo',
        type,
      }),
      stubs: {
        UrlSync,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findFilteredSearch = () => wrapper.find(FilteredSearchBar);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('tokens')
      .find(token => token.type === type);

  describe('default', () => {
    beforeEach(() => {
      vuexStore = createStore();
      wrapper = createComponent(vuexStore);
    });

    it('renders FilteredSearchBar component', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
        authors: { data: userValues },
        assignees: { data: userValues },
      });
      wrapper = createComponent(vuexStore);
    });

    it('displays the milestone, label, author and assignee tokens', () => {
      const tokens = findFilteredSearch().props('tokens');
      expect(tokens).toHaveLength(4);
      expect(tokens[0].type).toBe(milestoneTokenType);
      expect(tokens[1].type).toBe(labelsTokenType);
      expect(tokens[2].type).toBe(authorTokenType);
      expect(tokens[3].type).toBe(assigneeTokenType);
    });

    it('provides the initial milestone token', () => {
      const { initialMilestones: milestoneToken } = getSearchToken(milestoneTokenType);

      expect(milestoneToken).toHaveLength(filterMilestones.length);
    });

    it('provides the initial label token', () => {
      const { initialLabels: labelToken } = getSearchToken(labelsTokenType);

      expect(labelToken).toHaveLength(filterLabels.length);
    });

    it('provides the initial author token', () => {
      const { initialAuthors: authorToken } = getSearchToken(authorTokenType);

      expect(authorToken).toHaveLength(filterUsers.length);
    });

    it('provides the initial assignee token', () => {
      const { initialAuthors: assigneeToken } = getSearchToken(assigneeTokenType);

      expect(assigneeToken).toHaveLength(filterUsers.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
      });
      wrapper = createComponent(vuexStore);
      jest.spyOn(utils, 'processFilters');
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      const filters = [
        { type: 'milestone', value: getFilterParams(filterMilestones, { key: 'data' })[2] },
        { type: 'labels', value: getFilterParams(filterLabels, { key: 'data' })[2] },
        { type: 'labels', value: getFilterParams(filterLabels, { key: 'data' })[4] },
        { type: 'assignee', value: getFilterParams(filterUsers, { key: 'data', prop: 'name' })[2] },
        { type: 'author', value: getFilterParams(filterUsers, { key: 'data', prop: 'name' })[1] },
      ];

      findFilteredSearch().vm.$emit('onFilter', filters);

      expect(utils.processFilters).toHaveBeenCalledWith(filters);

      expect(setFiltersMock).toHaveBeenCalledWith(expect.anything(), {
        selectedMilestone: selectedMilestoneParams[2],
        selectedLabelList: [selectedLabelParams[2], selectedLabelParams[4]],
        selectedAssignee: selectedUserParams[2],
        selectedAuthor: selectedUserParams[1],
      });
    });
  });

  describe.each`
    stateKey               | payload                       | paramKey               | value
    ${'selectedMilestone'} | ${selectedMilestoneParams[3]} | ${'milestone_title'}   | ${milestoneValues[3]}
    ${'selectedMilestone'} | ${selectedMilestoneParams[0]} | ${'milestone_title'}   | ${milestoneValues[0]}
    ${'selectedLabelList'} | ${selectedLabelParams}        | ${'label_name'}        | ${labelValues}
    ${'selectedLabelList'} | ${selectedLabelParams}        | ${'label_name'}        | ${labelValues}
    ${'selectedAuthor'}    | ${selectedUserParams[0]}      | ${'author_username'}   | ${userValues[0]}
    ${'selectedAssignee'}  | ${selectedUserParams[1]}      | ${'assignee_username'} | ${userValues[1]}
  `(
    'with a $stateKey updates the $paramKey url parameter',
    ({ stateKey, payload, paramKey, value }) => {
      beforeEach(() => {
        commonUtils.historyPushState = jest.fn();
        urlUtils.mergeUrlParams = jest.fn();

        mock = new MockAdapter(axios);
        wrapper = createComponent(storeConfig);

        wrapper.vm.$store.dispatch('filters/setFilters', {
          ...initialFilterBarState,
          [stateKey]: payload,
        });
      });
      it(`sets the ${paramKey} url parameter`, async () => {
        await shouldMergeUrlParams(wrapper, {
          ...defaultParams,
          [paramKey]: value,
        });
      });
    },
  );
});
