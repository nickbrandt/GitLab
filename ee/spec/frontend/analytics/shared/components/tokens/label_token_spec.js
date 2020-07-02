import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
import LabelToken from 'ee/analytics/shared/components/tokens/label_token.vue';
import { mockLabels } from './mock_data';

describe('LabelToken', () => {
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
    fetchData: jest.fn(),
  };
  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const createComponent = (props = {}, options = { stubs }) => {
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
  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllLabelSuggestions = () => wrapper.findAll({ ref: 'labelItem' });
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  it('renders a loading icon', () => {
    createComponent({ config: { ...defaultConfig, isLoading: true }, value: {} }, { stubs });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('suggestions', () => {
    it('renders a suggestion for each item', () => {
      createComponent();

      const res = findAllLabelSuggestions();
      expect(res).toHaveLength(mockLabels.length);

      mockLabels.forEach((m, index) => {
        expect(res.at(index).html()).toContain(m.title);
      });
    });

    describe('default suggestions', () => {
      it.each`
        text      | dropdownIndex
        ${'None'} | ${0}
        ${'Any'}  | ${1}
      `('renders the "$text" suggestion', ({ text, dropdownIndex }) => {
        createComponent(null);

        expect(findFilteredSearchSuggestion(dropdownIndex).text()).toEqual(text);
      });
    });
  });

  describe('search', () => {
    describe('when no search term is given', () => {
      it('calls `fetchData` with an empty search term', () => {
        createComponent({
          value: defaultValue,
        });

        expect(defaultConfig.fetchData).toHaveBeenCalledWith('');
      });
    });

    describe('when the search term "Peaches castle" is given', () => {
      const data = "Peach's castle";
      it('calls `fetchData` with the search term', () => {
        createComponent({ value: { data } });

        expect(defaultConfig.fetchData).toHaveBeenCalledWith(data);
      });
    });

    describe('when the input changes', () => {
      const data = 'Moo moo farm';
      it('calls `fetchData` with the updated search term', () => {
        createComponent({ value: defaultValue }, { stubs: { GlFilteredSearchToken } });
        expect(defaultConfig.fetchData).not.toHaveBeenCalledWith(data);

        findFilteredSearchToken().vm.$emit('input', { data });
        expect(defaultConfig.fetchData).toHaveBeenCalledWith(data);
      });
    });
  });
});
