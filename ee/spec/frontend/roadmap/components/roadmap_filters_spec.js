import { GlSegmentedControl, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import RoadmapFilters from 'ee/roadmap/components/roadmap_filters.vue';
import { PRESET_TYPES, EPICS_STATES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import {
  mockSortedBy,
  mockTimeframeInitialDate,
  mockAuthorTokenConfig,
  mockLabelTokenConfig,
  mockMilestoneTokenConfig,
  mockConfidentialTokenConfig,
  mockEpicTokenConfig,
  mockReactionEmojiTokenConfig,
} from 'ee_jest/roadmap/mock_data';

import { TEST_HOST } from 'helpers/test_constants';
import { visitUrl, mergeUrlParams, updateHistory } from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  mergeUrlParams: jest.fn(),
  visitUrl: jest.fn(),
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
  updateHistory: jest.requireActual('~/lib/utils/url_utility').updateHistory,
}));

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epicsState = EPICS_STATES.ALL,
  sortedBy = mockSortedBy,
  groupFullPath = 'gitlab-org',
  listEpicsPath = '/groups/gitlab-org/-/epics',
  groupMilestonesPath = '/groups/gitlab-org/-/milestones.json',
  timeframe = getTimeframeForMonthsView(mockTimeframeInitialDate),
  filterParams = {},
} = {}) => {
  const localVue = createLocalVue();
  const store = createStore();

  localVue.use(Vuex);

  store.dispatch('setInitialData', {
    presetType,
    epicsState,
    sortedBy,
    filterParams,
    timeframe,
  });

  return shallowMount(RoadmapFilters, {
    localVue,
    store,
    provide: {
      groupFullPath,
      groupMilestonesPath,
      listEpicsPath,
    },
  });
};

describe('RoadmapFilters', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('selectedEpicStateTitle', () => {
      it.each`
        returnValue       | epicsState
        ${'All epics'}    | ${EPICS_STATES.ALL}
        ${'Open epics'}   | ${EPICS_STATES.OPENED}
        ${'Closed epics'} | ${EPICS_STATES.CLOSED}
      `(
        'returns string "$returnValue" when epicsState represents `$epicsState`',
        ({ returnValue, epicsState }) => {
          wrapper.vm.$store.dispatch('setEpicsState', epicsState);

          expect(wrapper.vm.selectedEpicStateTitle).toBe(returnValue);
        },
      );
    });
  });

  describe('watch', () => {
    describe('urlParams', () => {
      it('updates window URL based on presence of props for state, filtered search and sort criteria', async () => {
        wrapper.vm.$store.dispatch('setEpicsState', EPICS_STATES.CLOSED);
        wrapper.vm.$store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
        });
        wrapper.vm.$store.dispatch('setSortedBy', 'end_date_asc');

        await wrapper.vm.$nextTick();

        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?state=${EPICS_STATES.CLOSED}&sort=end_date_asc&author_username=root&label_name%5B%5D=Bug&milestone_title=4.0&confidential=true`,
        );
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      updateHistory({ url: TEST_HOST, title: document.title, replace: true });
    });

    it('renders roadmap layout switching buttons', () => {
      const layoutSwitches = wrapper.find(GlSegmentedControl);

      expect(layoutSwitches.exists()).toBe(true);
      expect(layoutSwitches.props('checked')).toBe(PRESET_TYPES.MONTHS);
      expect(layoutSwitches.props('options')).toEqual([
        { text: 'Quarters', value: PRESET_TYPES.QUARTERS },
        { text: 'Months', value: PRESET_TYPES.MONTHS },
        { text: 'Weeks', value: PRESET_TYPES.WEEKS },
      ]);
    });

    it('switching layout using roadmap layout switching buttons causes page to reload with selected layout', () => {
      wrapper.find(GlSegmentedControl).vm.$emit('input', PRESET_TYPES.OPENED);

      expect(mergeUrlParams).toHaveBeenCalledWith(
        expect.objectContaining({ layout: PRESET_TYPES.OPENED }),
        `${TEST_HOST}/`,
      );
      expect(visitUrl).toHaveBeenCalled();
    });

    it('renders epics state toggling dropdown', () => {
      const epicsStateDropdown = wrapper.find(GlDropdown);

      expect(epicsStateDropdown.exists()).toBe(true);
      expect(epicsStateDropdown.findAll(GlDropdownItem)).toHaveLength(3);
    });

    describe('FilteredSearchBar', () => {
      const mockInitialFilterValue = [
        {
          type: 'author_username',
          value: { data: 'root', operator: '=' },
        },
        {
          type: 'author_username',
          value: { data: 'John', operator: '!=' },
        },
        {
          type: 'label_name',
          value: { data: 'Bug', operator: '=' },
        },
        {
          type: 'label_name',
          value: { data: 'Feature', operator: '!=' },
        },
        {
          type: 'milestone_title',
          value: { data: '4.0' },
        },
        {
          type: 'confidential',
          value: { data: true },
        },
        {
          type: 'my_reaction_emoji',
          value: { data: 'thumbs_up', operator: '!=' },
        },
      ];
      let filteredSearchBar;

      beforeEach(() => {
        filteredSearchBar = wrapper.find(FilteredSearchBar);
      });

      it('component is rendered with correct namespace & recent search key', () => {
        expect(filteredSearchBar.exists()).toBe(true);
        expect(filteredSearchBar.props('namespace')).toBe('gitlab-org');
        expect(filteredSearchBar.props('recentSearchesStorageKey')).toBe('epics');
      });

      it('includes `Author`, `Milestone`, `Confidential`, `Epic` and `Label` tokens when user is not logged in', () => {
        expect(filteredSearchBar.props('tokens')).toEqual([
          mockAuthorTokenConfig,
          mockLabelTokenConfig,
          mockMilestoneTokenConfig,
          mockConfidentialTokenConfig,
          mockEpicTokenConfig,
        ]);
      });

      it('includes "Start date" and "Due date" sort options', () => {
        expect(filteredSearchBar.props('sortOptions')).toEqual([
          {
            id: 1,
            title: 'Start date',
            sortDirection: {
              descending: 'start_date_desc',
              ascending: 'start_date_asc',
            },
          },
          {
            id: 2,
            title: 'Due date',
            sortDirection: {
              descending: 'end_date_desc',
              ascending: 'end_date_asc',
            },
          },
        ]);
      });

      it('has initialFilterValue prop set to array of formatted values based on `filterParams`', async () => {
        wrapper.vm.$store.dispatch('setFilterParams', {
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });

        await wrapper.vm.$nextTick();

        expect(filteredSearchBar.props('initialFilterValue')).toEqual(mockInitialFilterValue);
      });

      it('fetches filtered epics when `onFilter` event is emitted', async () => {
        jest.spyOn(wrapper.vm, 'setFilterParams');
        jest.spyOn(wrapper.vm, 'fetchEpics');

        await wrapper.vm.$nextTick();

        filteredSearchBar.vm.$emit('onFilter', mockInitialFilterValue);

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.setFilterParams).toHaveBeenCalledWith({
          authorUsername: 'root',
          labelName: ['Bug'],
          milestoneTitle: '4.0',
          confidential: true,
          'not[authorUsername]': 'John',
          'not[labelName]': ['Feature'],
          'not[myReactionEmoji]': 'thumbs_up',
        });
        expect(wrapper.vm.fetchEpics).toHaveBeenCalled();
      });

      it('fetches epics with updated sort order when `onSort` event is emitted', async () => {
        jest.spyOn(wrapper.vm, 'setSortedBy');
        jest.spyOn(wrapper.vm, 'fetchEpics');

        await wrapper.vm.$nextTick();

        filteredSearchBar.vm.$emit('onSort', 'end_date_asc');

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.setSortedBy).toHaveBeenCalledWith('end_date_asc');
        expect(wrapper.vm.fetchEpics).toHaveBeenCalled();
      });

      describe('when user is logged in', () => {
        beforeAll(() => {
          gon.current_user_id = 1;
          gon.current_user_fullname = 'Administrator';
          gon.current_username = 'root';
          gon.current_user_avatar_url = 'avatar/url';
        });

        it('includes `Author`, `Milestone`, `Confidential`, `Label` and `My-Reaction` tokens', () => {
          expect(filteredSearchBar.props('tokens')).toEqual([
            {
              ...mockAuthorTokenConfig,
              preloadedAuthors: [
                {
                  id: 1,
                  name: 'Administrator',
                  username: 'root',
                  avatar_url: 'avatar/url',
                },
              ],
            },
            mockLabelTokenConfig,
            mockMilestoneTokenConfig,
            mockConfidentialTokenConfig,
            mockEpicTokenConfig,
            mockReactionEmojiTokenConfig,
          ]);
        });
      });
    });
  });
});
