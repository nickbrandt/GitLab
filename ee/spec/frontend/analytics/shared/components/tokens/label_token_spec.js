import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import LabelToken from 'ee/analytics/shared/components/tokens/label_token.vue';
import { mockLabels } from './mock_data';

describe('MilestoneToken', () => {
  let wrapper;
  const defaultValue = { data: '' };
  const defaultConfig = {
    icon: 'labels',
    title: 'Label',
    type: 'label',
    labels: mockLabels,
    unique: false,
    symbol: '~',
    isLoading: false,
  };
  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const createComponent = (props = {}, options) => {
    wrapper = shallowMount(LabelToken, {
      propsData: {
        config: defaultConfig,
        value: defaultValue,
        ...props,
      },
      ...options,
    });
  };

  const findFilteredSearchSuggestion = index =>
    wrapper.findAll(GlFilteredSearchSuggestion).at(index);
  const findAllLabelSuggestions = () => wrapper.findAll({ ref: 'labelItem' });
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  it('renders a loading icon', () => {
    createComponent({ config: { isLoading: true }, value: {} }, { stubs });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('suggestions', () => {
    describe('default suggestions', () => {
      it.each`
        text      | dropdownIndex
        ${'None'} | ${0}
        ${'Any'}  | ${1}
      `('renders the "$text" suggestion', ({ text, dropdownIndex }) => {
        createComponent(null, { stubs });

        expect(findFilteredSearchSuggestion(dropdownIndex).text()).toEqual(text);
      });
    });

    describe('when no search term is given', () => {
      it('renders two label suggestions', () => {
        createComponent(null, { stubs });

        expect(findAllLabelSuggestions()).toHaveLength(2);
      });
    });

    describe('when the search term "Alero" is given', () => {
      it('renders one label suggestion that matches the search term', () => {
        createComponent({ value: { data: 'Alero' } }, { stubs });

        expect(findAllLabelSuggestions()).toHaveLength(1);
      });
    });
  });
});
