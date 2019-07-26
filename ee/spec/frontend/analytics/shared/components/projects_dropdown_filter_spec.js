import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import Api from '~/api';

jest.mock('~/api', () => ({
  groupProjects: jest.fn(),
}));

const projects = [
  {
    id: 1,
    name: 'foo',
  },
  {
    id: 2,
    name: 'foobar',
  },
  {
    id: 3,
    name: 'foooooooo',
  },
];

describe('ProjectsDropdownFilter component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectsDropdownFilter, {
      sync: false,
      propsData: {
        groupId: 1,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    jest.spyOn($.fn, 'glDropdown');
    Api.groupProjects.mockImplementation((groupId, term, options, callback) => {
      callback(projects);
    });
  });

  const findDropdown = () => wrapper.find('.dropdown');
  const openDropdown = () => {
    $(findDropdown().element)
      .parent()
      .trigger('shown.bs.dropdown');
  };
  const findDropdownItems = () => findDropdown().findAll('a');

  describe('when multiSelect is false', () => {
    beforeEach(() => {
      createComponent({ multiSelect: false });
    });

    it('should call glDropdown', () => {
      expect($.fn.glDropdown).toHaveBeenCalled();
    });

    describe('on project click', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('should emit the "selected" event with the selected project', () => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
        ]);
      });

      it('should change selection when new project is clicked', () => {
        findDropdownItems()
          .at(1)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[1]]],
          },
        ]);
      });
    });
  });

  describe('when multiSelect is true', () => {
    beforeEach(() => {
      createComponent({ multiSelect: true });
    });

    describe('on project click', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('should add to selection when new project is clicked', () => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        findDropdownItems()
          .at(1)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
          {
            name: 'selected',
            args: [[projects[0], projects[1]]],
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
            args: [[projects[0]]],
          },
          {
            name: 'selected',
            args: [[]],
          },
        ]);
      });
    });
  });
});
