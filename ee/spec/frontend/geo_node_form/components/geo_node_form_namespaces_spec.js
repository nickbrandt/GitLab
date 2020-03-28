import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlIcon, GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import GeoNodeFormNamespaces from 'ee/geo_node_form/components/geo_node_form_namespaces.vue';
import store from 'ee/geo_node_form/store';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/flash');

describe('GeoNodeFormNamespaces', () => {
  let wrapper;

  const defaultProps = {
    selectedNamespaces: [],
  };

  const actionSpies = {
    fetchSyncNamespaces: jest.fn(),
    toggleNamespace: jest.fn(),
    isSelected: jest.fn(),
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(GeoNodeFormNamespaces, {
      localVue,
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().find(GlSearchBoxByType);
  const findDropdownItems = () => findGlDropdown().findAll('li');
  const findDropdownItemsText = () => findDropdownItems().wrappers.map(w => w.text());
  const findGlIcons = () => wrapper.findAll(GlIcon);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    it('renders findGlDropdownSearch', () => {
      expect(findGlDropdownSearch().exists()).toBe(true);
    });

    describe('findDropdownItems', () => {
      beforeEach(() => {
        delete actionSpies.isSelected;
        createComponent({
          selectedNamespaces: [[MOCK_SYNC_NAMESPACES[0].id]],
        });
        wrapper.vm.$store.state.synchronizationNamespaces = MOCK_SYNC_NAMESPACES;
      });

      it('renders an instance for each namespace', () => {
        expect(findDropdownItemsText()).toStrictEqual(MOCK_SYNC_NAMESPACES.map(n => n.name));
      });

      it('hides GlIcon if namespace not in selectedNamespaces', () => {
        expect(findGlIcons().wrappers.every(w => w.classes('invisible'))).toBe(true);
      });
    });
  });

  describe('watchers', () => {
    describe('namespaceSearch', () => {
      const namespaceSearch = 'test search';

      beforeEach(() => {
        createComponent();
        wrapper.setData({
          namespaceSearch,
        });
      });

      it('should wait 500ms before calling fetchSyncNamespaces', () => {
        expect(actionSpies.fetchSyncNamespaces).not.toHaveBeenCalledWith(namespaceSearch);

        jest.advanceTimersByTime(500); // Debounce
        expect(actionSpies.fetchSyncNamespaces).toHaveBeenCalledWith(namespaceSearch);
        expect(actionSpies.fetchSyncNamespaces).toHaveBeenCalledTimes(1);
      });

      it('should call fetchSyncNamespaces once with the latest search term', () => {
        expect(actionSpies.fetchSyncNamespaces).not.toHaveBeenCalledWith(namespaceSearch);
        wrapper.setData({
          namespaceSearch: 'test search2',
        });

        jest.advanceTimersByTime(500); // Debounce
        expect(actionSpies.fetchSyncNamespaces).toHaveBeenCalledWith('test search2');
        expect(actionSpies.fetchSyncNamespaces).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('methods', () => {
    describe('toggleNamespace', () => {
      beforeEach(() => {
        delete actionSpies.toggleNamespace;
        createComponent({
          selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id],
        });
      });

      describe('when namespace is in selectedNamespaces', () => {
        it('emits `removeSyncOption`', () => {
          wrapper.vm.toggleNamespace(MOCK_SYNC_NAMESPACES[0]);
          expect(wrapper.emitted('removeSyncOption')).toBeTruthy();
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('emits `addSyncOption`', () => {
          wrapper.vm.toggleNamespace(MOCK_SYNC_NAMESPACES[1]);
          expect(wrapper.emitted('addSyncOption')).toBeTruthy();
        });
      });
    });

    describe('isSelected', () => {
      beforeEach(() => {
        delete actionSpies.isSelected;
        createComponent({
          selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id],
        });
      });

      describe('when namespace is in selectedNamespaces', () => {
        it('returns `true`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[0])).toBeTruthy();
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('returns `false`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[1])).toBeFalsy();
        });
      });
    });

    describe('computed', () => {
      describe('dropdownTitle', () => {
        describe('when selectedNamespaces is empty', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [],
            });
          });

          it('returns `Select groups to replicate`', () => {
            expect(wrapper.vm.dropdownTitle).toBe('Select groups to replicate');
          });
        });

        describe('when selectedNamespaces length === 1', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id],
            });
          });

          it('returns `this.selectedNamespaces.length` group selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedNamespaces.length} group selected`,
            );
          });
        });

        describe('when selectedNamespaces length > 1', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id, MOCK_SYNC_NAMESPACES[1].id],
            });
          });

          it('returns `this.selectedNamespaces.length` group selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedNamespaces.length} groups selected`,
            );
          });
        });
      });

      describe('noSyncNamespaces', () => {
        describe('when synchronizationNamespaces.length > 0', () => {
          beforeEach(() => {
            createComponent();
            wrapper.vm.$store.state.synchronizationNamespaces = MOCK_SYNC_NAMESPACES;
          });

          it('returns `false`', () => {
            expect(wrapper.vm.noSyncNamespaces).toBeFalsy();
          });
        });
      });

      describe('when synchronizationNamespaces.length === 0', () => {
        beforeEach(() => {
          createComponent();
          wrapper.vm.$store.state.synchronizationNamespaces = [];
        });

        it('returns `true`', () => {
          expect(wrapper.vm.noSyncNamespaces).toBeTruthy();
        });
      });
    });
  });
});
