import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlButton } from '@gitlab/ui';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import store from 'ee/geo_replicable/store';
import { DEFAULT_SEARCH_DELAY } from 'ee/geo_replicable/store/constants';

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
      store,
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findNavContainer = () => wrapper.find('nav');
  const findGlDropdown = () => findNavContainer().find(GlDropdown);
  const findGlDropdownItems = () => findNavContainer().findAll(GlDropdownItem);
  const findDropdownItemsText = () => findGlDropdownItems().wrappers.map(w => w.text());
  const findGlSearchBox = () => findNavContainer().find(GlSearchBoxByType);
  const findGlButton = () => findNavContainer().find(GlButton);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nav container always', () => {
      expect(findNavContainer().exists()).toBeTruthy();
    });

    it('renders dropdown always', () => {
      expect(findGlDropdown().exists()).toBeTruthy();
    });

    describe('Filter options', () => {
      it('renders a dropdown item for each filterOption', () => {
        expect(findDropdownItemsText()).toStrictEqual(wrapper.vm.filterOptions.map(n => n.label));
      });

      it('clicking a dropdown item calls setFilter with its index', () => {
        const index = 1;
        findGlDropdownItems()
          .at(index)
          .find('button')
          .trigger('click');

        expect(actionSpies.setFilter).toHaveBeenCalledWith(index);
      });
    });

    it('renders a search box always', () => {
      expect(findGlSearchBox().exists()).toBeTruthy();
    });

    describe('Re-sync all button', () => {
      it('renders always', () => {
        expect(findGlButton().exists()).toBeTruthy();
      });

      it('calls initiateAllReplicableSyncs when clicked', () => {
        findGlButton().trigger('click');
        expect(actionSpies.initiateAllReplicableSyncs).toHaveBeenCalled();
      });
    });
  });

  // TODO: These specs should fixed once we have a proper mock for debounce
  // https://gitlab.com/gitlab-org/gitlab/-/issues/213925
  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip('when search changes', () => {
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
