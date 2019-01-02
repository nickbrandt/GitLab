import Vue from 'vue';
import component from 'ee/billings/components/subscription_table_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Subscription Table Row', () => {
  let vm;
  let props;
  const Component = Vue.extend(component);
  const header = {
    icon: 'monitor',
    title: 'Test title',
  };
  const columns = [
    {
      id: 'a',
      label: 'Column A',
      value: 100,
      colClass: 'number',
    },
    {
      id: 'b',
      label: 'Column B',
      value: 200,
      popover: {
        content: 'This is a tooltip',
      },
    },
  ];

  afterEach(() => {
    vm.$destroy();
  });

  describe('when loaded', () => {
    beforeEach(() => {
      props = { header, columns };
      vm = mountComponent(Component, props);
    });

    it(`should render one header cell and ${columns.length} visible columns in total`, () => {
      expect(vm.$el.querySelectorAll('.grid-cell')).toHaveLength(columns.length + 1);
    });

    it(`should not render a hidden column`, () => {
      const hiddenColIdx = columns.find(c => !c.display);
      const hiddenCol = vm.$el.querySelectorAll('.grid-cell:not(.header-cell)')[hiddenColIdx];

      expect(hiddenCol).toBe(undefined);
    });

    it('should render a title in the header cell', () => {
      expect(vm.$el.querySelector('.header-cell').textContent).toContain(props.header.title);
    });

    it('should render an icon in the header cell', () => {
      expect(vm.$el.querySelector(`.header-cell .ic-${header.icon}`)).not.toBe(null);
    });

    columns.forEach((col, idx) => {
      it(`should render label and value in column ${col.label}`, () => {
        const currentCol = vm.$el.querySelectorAll('.grid-cell:not(.header-cell)')[idx];

        expect(currentCol.querySelector('.property-label').textContent).toContain(col.label);
        expect(currentCol.querySelector('.property-value').textContent).toContain(col.value);
      });
    });

    it('should append the "number" css class to property value in "Column A"', () => {
      const currentCol = vm.$el.querySelectorAll('.grid-cell:not(.header-cell)')[0];

      expect(currentCol.querySelector('.property-value').classList.contains('number')).toBe(true);
    });

    it('should render an info icon in "Column B"', () => {
      const currentCol = vm.$el.querySelectorAll('.grid-cell:not(.header-cell)')[1];

      expect(currentCol.querySelector('.btn-help')).not.toBe(null);
    });
  });
});
