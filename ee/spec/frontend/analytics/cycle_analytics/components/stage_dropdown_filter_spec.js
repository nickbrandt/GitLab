import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import StageDropdownFilter from 'ee/analytics/cycle_analytics/components/stage_dropdown_filter.vue';

jest.mock('~/api', () => ({
  groupProjects: jest.fn(),
}));

const stages = [
  {
    name: 'issue',
  },
  {
    name: 'plan',
  },
  {
    name: 'code',
  },
];

describe('StageDropdownFilter component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(StageDropdownFilter, {
      sync: false,
      propsData: {
        stages,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent({ multiSelect: false });
  });

  const findDropdown = () => wrapper.find('.dropdown');
  const openDropdown = () => {
    $(findDropdown().element)
      .parent()
      .trigger('shown.bs.dropdown');
  };
  const findDropdownItems = () => findDropdown().findAll('a');

  describe('on stage click', () => {
    beforeEach(() => {
      openDropdown();

      return wrapper.vm.$nextTick();
    });

    it('should add to selection when new stage is clicked', () => {
      findDropdownItems()
        .at(0)
        .trigger('click');

      findDropdownItems()
        .at(1)
        .trigger('click');

      expect(wrapper.emittedByOrder()).toEqual([
        {
          name: 'selected',
          args: [[stages[0]]],
        },
        {
          name: 'selected',
          args: [[stages[0], stages[1]]],
        },
      ]);
    });

    it('should remove from selection when clicked again', () => {
      const item = findDropdownItems().at(0);

      item.trigger('click');
      item.trigger('click');

      expect(wrapper.emittedByOrder()).toEqual([
        {
          name: 'selected',
          args: [[stages[0]]],
        },
        {
          name: 'selected',
          args: [[]],
        },
      ]);
    });
  });
});
