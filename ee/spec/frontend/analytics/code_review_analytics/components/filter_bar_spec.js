import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import FilterBar from 'ee/analytics/code_review_analytics/components/filter_bar.vue';
import createFiltersState from 'ee/analytics/shared/store/modules/filters/state';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import * as utils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { mockMilestones, mockLabels } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const milestoneTokenType = 'milestone';
const labelTokenType = 'labels';

describe('FilteredSearchBar', () => {
  let wrapper;
  let vuexStore;

  let setFiltersMock;

  const createStore = (initialState = {}) => {
    setFiltersMock = jest.fn();

    return new Vuex.Store({
      modules: {
        filters: {
          namespaced: true,
          state: {
            ...createFiltersState(),
            ...initialState,
          },
          actions: {
            fetchMilestones: jest.fn(),
            fetchLabels: jest.fn(),
            setFilters: setFiltersMock,
          },
        },
      },
    });
  };

  const createComponent = store =>
    shallowMount(FilterBar, {
      localVue,
      store,
      propsData: {
        projectPath: 'foo',
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findFilteredSearch = () => wrapper.find(FilteredSearchBar);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('tokens')
      .find(token => token.type === type);

  it('renders FilteredSearchBar component', () => {
    vuexStore = createStore();
    wrapper = createComponent(vuexStore);

    expect(findFilteredSearch().exists()).toBe(true);
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: mockMilestones },
        labels: { data: mockLabels },
      });
      wrapper = createComponent(vuexStore);
    });

    it('displays the milestone and label token', () => {
      const tokens = findFilteredSearch().props('tokens');

      expect(tokens).toHaveLength(2);
      expect(tokens[0].type).toBe(milestoneTokenType);
      expect(tokens[1].type).toBe(labelTokenType);
    });

    it('displays options in the milestone token', () => {
      const { milestones: milestoneToken } = getSearchToken(milestoneTokenType);

      expect(milestoneToken).toHaveLength(mockMilestones.length);
    });

    it('displays options in the label token', () => {
      const { labels: labelToken } = getSearchToken(labelTokenType);

      expect(labelToken).toHaveLength(mockLabels.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: mockMilestones },
        labels: { data: mockLabels },
      });
      wrapper = createComponent(vuexStore);
      jest.spyOn(utils, 'processFilters');
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      const filters = [
        { type: 'milestone', value: { data: 'my-milestone', operator: '=' } },
        { type: 'labels', value: { data: 'my-label', operator: '=' } },
      ];

      findFilteredSearch().vm.$emit('onFilter', filters);

      expect(utils.processFilters).toHaveBeenCalledWith(filters);

      expect(setFiltersMock).toHaveBeenCalledWith(
        expect.anything(),
        {
          selectedLabelList: [{ value: 'my-label', operator: '=' }],
          selectedMilestone: { value: 'my-milestone', operator: '=' },
        },
        undefined,
      );
    });
  });
});
