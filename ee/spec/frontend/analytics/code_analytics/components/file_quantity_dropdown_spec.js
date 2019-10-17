import { shallowMount } from '@vue/test-utils';
import { GlDropdownItem } from '@gitlab/ui';
import FileQuantityDropdown from 'ee/analytics/code_analytics/components/file_quantity_dropdown.vue';
import { DEFAULT_FILE_QUANTITY } from '../mock_data';

describe('FileQuantityDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}) =>
    shallowMount(FileQuantityDropdown, {
      propsData: {
        selected: DEFAULT_FILE_QUANTITY,
        ...props,
      },
    });

  const findDropdownElements = () => wrapper.findAll(GlDropdownItem);
  const findFirstDropdownElement = () => findDropdownElements().at(0);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('the default behaviour acts as expected', () => {
    it('renders the default dropdown items', () => {
      expect(findDropdownElements().length).toBe(5);
    });

    it('displays the correct label for the first dropdown item', () => {
      expect(findFirstDropdownElement().text()).toBe('25');
    });

    it('emits the "selected" event with the selected item value', () => {
      findFirstDropdownElement().vm.$emit('click');
      expect(wrapper.emitted().selected[0]).toEqual([25]);
    });
  });

  describe('the component renders the correct dropdown text when selected is passed through', () => {
    beforeEach(() => {
      wrapper = createComponent({ selected: 250, fileQuantityOptions: [100, 250, 500] });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the default dropdown items', () => {
      expect(findDropdownElements().length).toBe(3);
    });

    it('displays the correct label for the first dropdown item', () => {
      expect(findFirstDropdownElement().text()).toBe('100');
    });

    it('emits the "selected" event with the selected item value', () => {
      findFirstDropdownElement().vm.$emit('click');
      expect(wrapper.emitted().selected[0]).toEqual([100]);
    });
  });
});
