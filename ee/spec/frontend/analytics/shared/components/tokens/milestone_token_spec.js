import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
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

    describe('when no search term is given', () => {
      it('renders two milestone suggestions', () => {
        createComponent({ config, value }, { stubs });

        expect(findAllMilestoneSuggestions()).toHaveLength(2);
      });
    });

    describe('when the search term "v4" is given', () => {
      it('renders one milestone suggestion that matches the search term', () => {
        value.data = 'v4';

        createComponent({ config, value }, { stubs });

        expect(findAllMilestoneSuggestions()).toHaveLength(1);
      });
    });
  });
});
