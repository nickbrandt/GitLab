import { shallowMount } from '@vue/test-utils';
import DevopsAdoptionTableCellFlag from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_table_cell_flag.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('DevopsAdoptionTableCellFlag', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(DevopsAdoptionTableCellFlag, {
      propsData: {
        enabled: true,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('enabled', () => {
    beforeEach(() => createComponent());

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains a tooltip', () => {
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Adopted');
    });

    describe('when the enabled flag is changed to false', () => {
      beforeEach(async () => {
        wrapper.setProps({ enabled: false });

        await wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('displays the correct tooltip', () => {
        const tooltip = getBinding(wrapper.element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Not adopted');
      });
    });

    describe('with a variant specified', () => {
      beforeEach(async () => {
        wrapper.setProps({ variant: 'primary' });

        await wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });

  describe('disabled', () => {
    beforeEach(() => createComponent({ enabled: false }));

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('contains a tooltip', () => {
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Not adopted');
    });

    describe('when the enabled flag is changed to true', () => {
      beforeEach(async () => {
        wrapper.setProps({ enabled: true });

        await wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('displays the correct tooltip', () => {
        const tooltip = getBinding(wrapper.element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('Adopted');
      });
    });
  });
});
