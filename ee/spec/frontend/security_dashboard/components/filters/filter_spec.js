import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import Filter from 'ee/security_dashboard/components/filters/filter.vue';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';

const generateOption = index => ({
  name: `Option ${index}`,
  id: `option-${index}`,
});

const generateOptions = length => {
  return Array.from({ length }).map((_, i) => generateOption(i));
};

describe('Filter component', () => {
  let wrapper;

  const createWrapper = propsData => {
    wrapper = mount(Filter, {
      stubs: {
        ...stubChildren(Filter),
        GlDropdown: false,
        GlDropdownItem: false,
        GlSearchBoxByType: false,
      },
      propsData,
      attachToDocument: true,
    });
  };

  const findSearchInput = () =>
    wrapper.find({ ref: 'searchBox' }).exists() && wrapper.find({ ref: 'searchBox' }).find('input');
    const dropdownItemsCount = () => wrapper.findAll([data-testid="dropdown-item"]).length;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('severity', () => {
    let options;

    beforeEach(() => {
      options = generateOptions(8);
      const filter = {
        name: 'Severity',
        id: 'severity',
        options,
        selection: new Set([options[0].id, options[1].id, options[2].id]),
      };
      createWrapper({ filter });
    });

    it('should display all 8 severity options', () => {
      expect(dropdownItemsCount()).toEqual(8);
    });

    it('should correctly display the selected text', () => {
      const selectedText = trimText(wrapper.find('.dropdown-toggle').text());

      expect(selectedText).toBe(`${options[0].name} +2 more`);
    });

    it('should display "Severity" as the option name', () => {
      expect(wrapper.find('.js-name').text()).toContain('Severity');
    });

    it('should not have a search box', () => {
      expect(findSearchBox().exists()).toBe(false);
    });
  });

  describe('Project', () => {
    describe('when there are lots of projects', () => {
      const LOTS = 30;

      beforeEach(() => {
        const options = generateOptions(LOTS);
        const filter = {
          name: 'Project',
          id: 'project',
          options,
          selection: new Set([options[0].id]),
        };

        createWrapper({ filter });
      });

      it('should display a search box', () => {
        expect(findSearchBox().exists()).toBe(true);
      });

      it(`should show all projects`, () => {
        expect(dropdownItemsCount()).toBe(LOTS);
      });

      it('should show only matching projects when a search term is entered', async () => {
        findSearchBox().vm.$emit('input', '0');
        await wrapper.vm.$nextTick();

        expect(dropdownItemsCount()).toBe(3);
      });
    });
  });
});
