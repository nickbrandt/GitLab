import Vuex from 'vuex';
import Filter from 'ee/security_dashboard/components/filter.vue';
import createStore from 'ee/security_dashboard/store';
import { mount, createLocalVue } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Filter component', () => {
  let wrapper;
  let store;

  const createWrapper = propsData => {
    wrapper = mount(Filter, {
      stubs: {
        ...stubChildren(Filter),
        GlDropdown: false,
        GlSearchBoxByType: false,
      },
      propsData,
      store,
      attachToDocument: true,
    });
  };

  const findSearchInput = () =>
    wrapper.find({ ref: 'searchBox' }).exists() && wrapper.find({ ref: 'searchBox' }).find('input');
  const findDropdownToggle = () => wrapper.find('.dropdown-toggle');
  const dropdownItemsCount = () => wrapper.findAll('.dropdown-item').length;

  function isDropdownOpen() {
    const toggleButton = findDropdownToggle();
    return toggleButton.attributes('aria-expanded') === 'true';
  }

  function setProjectsCount(count) {
    const projects = new Array(count).fill(null).map((_, i) => ({
      name: i.toString(),
      id: i.toString(),
    }));

    store.dispatch('filters/setFilterOptions', {
      filterId: 'project_id',
      options: projects,
    });
  }

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('severity', () => {
    beforeEach(() => {
      createWrapper({ filterId: 'severity' });
    });

    it('should display all 8 severity options', () => {
      expect(dropdownItemsCount()).toEqual(8);
    });

    it('should display a check next to only the selected item', () => {
      expect(wrapper.findAll('.dropdown-item .js-check').length).toEqual(1);
    });

    it('should display "Severity" as the option name', () => {
      expect(wrapper.find('.js-name').text()).toContain('Severity');
    });

    it('should not have a search box', () => {
      expect(findSearchInput()).toBe(false);
    });

    it('should not be open', () => {
      expect(isDropdownOpen()).toBe(false);
    });

    describe('when the dropdown is open', () => {
      beforeEach(done => {
        findDropdownToggle().trigger('click');
        wrapper.vm.$root.$on('bv::dropdown::shown', () => {
          done();
        });
      });

      it('should keep the menu open after clicking on an item', () => {
        expect(isDropdownOpen()).toBe(true);
        wrapper.find('.dropdown-item').trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(isDropdownOpen()).toBe(true);
        });
      });

      it('should close the menu when the close button is clicked', () => {
        expect(isDropdownOpen()).toBe(true);
        wrapper.find({ ref: 'close' }).trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(isDropdownOpen()).toBe(false);
        });
      });
    });
  });

  describe('Project', () => {
    describe('when there are lots of projects', () => {
      const lots = 30;
      beforeEach(() => {
        createWrapper({ filterId: 'project_id', dashboardDocumentation: '' });
        setProjectsCount(lots);
        return wrapper.vm.$nextTick();
      });

      it('should display a search box', () => {
        expect(findSearchInput().exists()).toBe(true);
      });

      it(`should show all projects`, () => {
        expect(dropdownItemsCount()).toBe(lots);
      });

      it('should show only matching projects when a search term is entered', () => {
        const input = findSearchInput();
        input.vm.$el.value = '0';
        input.vm.$el.dispatchEvent(new Event('input'));
        return wrapper.vm.$nextTick().then(() => {
          expect(dropdownItemsCount()).toBe(3);
        });
      });
    });
  });
});
