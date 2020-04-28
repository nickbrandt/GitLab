import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlFilteredSearch } from '@gitlab/ui';
import FilterBar from 'ee/analytics/code_review_analytics/components/filter_bar.vue';
import createFiltersState from 'ee/analytics/code_review_analytics/store/modules/filters/state';
import { mockMilestones } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const milestoneTokenType = 'milestone';

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
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('availableTokens')
      .filter(token => token.type === type)[0];

  it('renders GlFilteredSearch component', () => {
    vuexStore = createStore();
    wrapper = createComponent(vuexStore);

    expect(findFilteredSearch().exists()).toBe(true);
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      vuexStore = createStore({ milestones: { data: mockMilestones } });
      wrapper = createComponent(vuexStore);
    });

    it('displays the milestone token', () => {
      const tokens = findFilteredSearch().props('availableTokens');

      expect(tokens).toHaveLength(1);
      expect(tokens[0].type).toBe(milestoneTokenType);
    });

    it('displays options in the milestone token', () => {
      const { options } = getSearchToken(milestoneTokenType);

      expect(options).toHaveLength(mockMilestones.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      vuexStore = createStore({ milestones: { data: mockMilestones } });
      wrapper = createComponent(vuexStore);
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      findFilteredSearch().vm.$emit('submit', [
        { type: 'milestone', value: { data: 'my-milestone', operator: '=' } },
      ]);

      expect(setFiltersMock).toHaveBeenCalledWith(
        expect.anything(),
        {
          label_name: undefined,
          milestone_title: ['my-milestone'],
        },
        undefined,
      );
    });
  });
});
