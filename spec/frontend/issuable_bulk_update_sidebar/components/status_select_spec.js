import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusSelect from '~/issuable_bulk_update_sidebar/components/status_select.vue';

describe('StatusSelect', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findHiddenInput = () => wrapper.find('input');
  function createComponent() {
    wrapper = shallowMount(StatusSelect);
  }

  describe('with no value selected', () => {
    it('renders default text', () => {
      createComponent();

      expect(findDropdown().props('text')).toBe('Select status');
    });
    it('renders dropdown items with `is-checked` prop set to `false`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(false);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });
  });

  describe('when selecting a value', () => {
    beforeEach(async () => {
      createComponent();
      findAllDropdownItems().at(0).vm.$emit('click');
      await wrapper.vm.$nextTick();
    });

    it('updates value of the hidden input', () => {
      expect(findHiddenInput().attributes('value')).toBe('reopen');
    });

    it('updates the dropdown text prop', () => {
      expect(findDropdown().props('text')).toBe('Open');
    });

    it('sets dropdown item `is-checked` prop to `true`', () => {
      const dropdownItems = findAllDropdownItems();

      expect(dropdownItems.at(0).props('isChecked')).toBe(true);
      expect(dropdownItems.at(1).props('isChecked')).toBe(false);
    });
  });
});
