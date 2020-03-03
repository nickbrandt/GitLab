import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlTabs, GlTab, GlFormInput, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import createStore from 'ee/geo_replicable/store';
import { DEFAULT_SEARCH_DELAY } from 'ee/geo_replicable/store/constants';
import { MOCK_REPLICABLE_TYPE } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableFilterBar', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    setFilter: jest.fn(),
    fetchReplicableItems: jest.fn(),
    initiateAllReplicableSyncs: jest.fn(),
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicableFilterBar, {
      localVue,
      store: createStore(MOCK_REPLICABLE_TYPE),
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlTabsContainer = () => wrapper.find(GlTabs);
  const findGlTab = () => findGlTabsContainer().findAll(GlTab);
  const findGlFormInput = () => findGlTabsContainer().find(GlFormInput);
  const findGlDropdown = () => findGlTabsContainer().find(GlDropdown);
  const findGlDropdownItem = () => findGlTabsContainer().find(GlDropdownItem);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('GlTab', () => {
      it('renders', () => {
        expect(findGlTabsContainer().exists()).toBe(true);
      });

      it('calls setFilter when input event is fired', () => {
        findGlTabsContainer().vm.$emit('input');
        expect(actionSpies.setFilter).toHaveBeenCalled();
      });
    });

    it('renders an instance of GlTab for each FilterOption', () => {
      expect(findGlTab().length).toBe(wrapper.vm.$store.state.filterOptions.length);
    });

    it('renders GlFormInput', () => {
      expect(findGlFormInput().exists()).toBe(true);
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    describe('GlDropDownItem', () => {
      it('renders', () => {
        expect(findGlDropdownItem().exists()).toBe(true);
      });

      it('calls initiateAllReplicableSyncs when clicked', () => {
        const innerButton = findGlDropdownItem().find('button');
        innerButton.trigger('click');
        expect(actionSpies.initiateAllReplicableSyncs).toHaveBeenCalled();
      });
    });
  });

  describe('when search changes', () => {
    beforeEach(() => {
      createComponent();
      actionSpies.fetchReplicableItems.mockClear(); // Will get called on init
      wrapper.vm.search = 'test search';
    });

    it(`should wait ${DEFAULT_SEARCH_DELAY}ms before calling setSearch`, () => {
      expect(actionSpies.setSearch).not.toHaveBeenCalledWith('test search');

      jest.runAllTimers(); // Debounce
      expect(actionSpies.setSearch).toHaveBeenCalledWith('test search');
    });

    it(`should wait ${DEFAULT_SEARCH_DELAY}ms before calling fetchReplicableItems`, () => {
      expect(actionSpies.fetchReplicableItems).not.toHaveBeenCalled();

      jest.runAllTimers(); // Debounce
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });

  describe('filterChange', () => {
    const testValue = 2;

    beforeEach(() => {
      createComponent();
      wrapper.vm.filterChange(testValue);
    });

    it('should call setFilter with the filterIndex', () => {
      expect(actionSpies.setFilter).toHaveBeenCalledWith(testValue);
    });

    it('should call fetchReplicableItems', () => {
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });
});
