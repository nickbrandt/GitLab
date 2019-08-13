import { mount, shallowMount } from '@vue/test-utils';
import LabelsSelector from 'ee/analytics/cycle_analytics/components/labels_selector.vue';
import { mockLabels } from '../../../../../../spec/javascripts/vue_shared/components/sidebar/labels_select/mock_data';

const labels = mockLabels.map(({ title, ...rest }) => ({ ...rest, name: title }));
const selectedLabel = labels[labels.length - 1];

describe('Cycle Analytics LabelsSelector', () => {
  function createComponent({ props = {}, shallow = true } = {}) {
    const func = shallow ? shallowMount : mount;
    return func(LabelsSelector, {
      propsData: {
        labels,
        selectedLabelId: props.selectedLabelId || null,
      },
      sync: false,
    });
  }

  let wrapper = null;

  describe('with no item selected', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will generate the list of labels', () => {
      // includes the blank option 'Select a label'
      expect(wrapper.findAll('gldropdownitem-stub').length).toEqual(labels.length + 1);

      labels.forEach(({ name }) => {
        expect(wrapper.text()).toContain(name);
      });
    });

    it('will render with the default option selected', () => {
      const activeItem = wrapper.find('[active="true"]');

      expect(activeItem.exists()).toBe(true);
      expect(activeItem.text()).toEqual('Select a label');
    });

    describe('when a dropdown item is clicked', () => {
      beforeEach(() => {
        wrapper = createComponent({ shallow: false });
      });

      it('will emit the "selectLabel" event', () => {
        expect(wrapper.emitted('selectLabel')).toBeUndefined();

        const elem = wrapper.findAll('.dropdown-item').at(2);
        elem.trigger('click');

        expect(wrapper.emitted('selectLabel').length > 0).toBe(true);
        expect(wrapper.emitted('selectLabel')[0]).toContain(mockLabels[1].id);
      });

      it('will emit the "clearLabel" event if it is the default item', () => {
        expect(wrapper.emitted('clearLabel')).toBeUndefined();

        const elem = wrapper.findAll('.dropdown-item').at(0);
        elem.trigger('click');

        expect(wrapper.emitted('clearLabel').length > 0).toBe(true);
      });
    });
  });

  describe('with selectedLabelId set', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { selectedLabelId: selectedLabel.id } });
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will set the active class', () => {
      const activeItem = wrapper.find('[active="true"]');

      expect(activeItem.exists()).toBe(true);
      expect(activeItem.text()).toEqual(selectedLabel.name);
    });
  });

  describe('with selectedLabelId set', () => {
    beforeEach(() => {
      wrapper = createComponent({
        selectedLabelId: 55,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will set the active class', () => {
      const activeItem = wrapper.find('[active="true"]');
      expect(activeItem.exists()).toBe(true);
      expect(activeItem.text()).toEqual('workflow::this-is-a-label');
    });
  });
});
