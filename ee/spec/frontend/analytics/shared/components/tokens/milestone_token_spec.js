import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
import MilestoneToken from 'ee/analytics/shared/components/tokens/milestone_token.vue';
import { mockMilestones } from './mock_data';

describe('MilestoneToken', () => {
  let wrapper;
  let value;
  let config;
  let stubs;

  const createComponent = (props = {}, options) => {
    wrapper = shallowMount(MilestoneToken, {
      propsData: props,
      ...options,
    });
  };

  const findFilteredSearchSuggestion = index =>
    wrapper.findAll(GlFilteredSearchSuggestion).at(index);
  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllMilestoneSuggestions = () => wrapper.findAll({ ref: 'milestoneItem' });
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    value = { data: '' };
    config = {
      icon: 'clock',
      title: 'Milestone',
      type: 'milestone',
      milestones: mockMilestones,
      unique: true,
      symbol: '%',
      isLoading: false,
      fetchData: jest.fn(),
    };
    stubs = {
      GlFilteredSearchToken: {
        template: `<div><slot name="suggestions"></slot></div>`,
      },
    };
  });

  it('renders a loading icon', () => {
    config.isLoading = true;

    createComponent({ config, value: {} }, { stubs });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('suggestions', () => {
    describe('default suggestions', () => {
      it.each`
        text          | dropdownIndex
        ${'None'}     | ${0}
        ${'Any'}      | ${1}
        ${'Upcoming'} | ${2}
        ${'Started'}  | ${3}
      `('renders the "$text" suggestion', ({ text, dropdownIndex }) => {
        createComponent({ config, value }, { stubs });

        expect(findFilteredSearchSuggestion(dropdownIndex).text()).toEqual(text);
      });
    });

    it("adds wrapping quotes to the suggestion's value when the milestone title has spaces", () => {
      createComponent({ config, value }, { stubs });

      const milestoneWithSpaces = findAllMilestoneSuggestions().at(0);

      expect(milestoneWithSpaces.props('value')).toBe(
        '"Sprint - Eligendi et aut pariatur ab rerum vel."',
      );
    });

    it('renders a suggestion for each item', () => {
      createComponent({ config, value }, { stubs });

      const res = findAllMilestoneSuggestions();
      expect(res).toHaveLength(mockMilestones.length);

      mockMilestones.forEach((m, index) => {
        expect(res.at(index).html()).toContain(m.title);
      });
    });
  });

  describe('search', () => {
    describe('when no search term is given', () => {
      it('calls `fetchData` with an empty search term', () => {
        createComponent({ config, value }, { stubs });

        expect(config.fetchData).toHaveBeenCalledWith('');
      });
    });

    describe('when the search term "v4" is given', () => {
      const query = 'v4';
      it('calls `fetchData` with the search term', () => {
        value.data = query;

        createComponent({ config, value }, { stubs });

        expect(config.fetchData).toHaveBeenCalledWith(query);
      });
    });

    describe('when the input changes', () => {
      const data = 'v4';
      it('calls `fetchData` with the updated search term', () => {
        createComponent({ config, value }, { stubs: { GlFilteredSearchToken } });
        expect(config.fetchData).not.toHaveBeenCalledWith(data);

        findFilteredSearchToken().vm.$emit('input', { data });
        expect(config.fetchData).toHaveBeenCalledWith(data);
      });
    });
  });
});
