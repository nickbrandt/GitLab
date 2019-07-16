import $ from 'jquery';
import Vue from 'vue';
import GLDropdown from '~/gl_dropdown'; // eslint-disable-line no-unused-vars
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import mountComponent from 'helpers/vue_mount_component_helper';

describe('ProjectsDropdownFilter component', () => {
  const Component = Vue.extend(ProjectsDropdownFilter);
  const props = {
    groupId: 1,
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    jest.spyOn($.fn, 'glDropdown');
    vm = mountComponent(Component, props);
  });

  it('should call glDropdown', () => {
    expect($.fn.glDropdown).toHaveBeenCalled();
  });

  describe('onClick', () => {
    const project = {
      id: 1,
      name: 'foo',
      path: 'bar',
    };
    const $el = $('<a></a>').data(project);
    const e = new Event('click');

    it('should emit the "setSelectedGroup" event', () => {
      jest.spyOn(vm, '$emit');

      vm.onClick({ $el, e });

      expect(vm.$emit).toHaveBeenCalledWith('selected', project);
    });
  });
});
