import $ from 'jquery';
import Vue from 'vue';
import GLDropdown from '~/gl_dropdown'; // eslint-disable-line no-unused-vars
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import mountComponent from 'helpers/vue_mount_component_helper';

describe('GroupsDropdownFilter component', () => {
  const Component = Vue.extend(GroupsDropdownFilter);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    jest.spyOn($.fn, 'glDropdown');
    vm = mountComponent(Component);
  });

  it('should call glDropdown', () => {
    expect($.fn.glDropdown).toHaveBeenCalled();
  });

  describe('onClick', () => {
    const group = {
      id: 1,
      name: 'foo',
      path: 'bar',
    };
    const $el = $('<a></a>').data(group);
    const e = new Event('click');

    it('should emit the "setSelectedGroup" event', () => {
      jest.spyOn(vm, '$emit');

      vm.onClick({ $el, e });

      expect(vm.$emit).toHaveBeenCalledWith('selected', group);
    });
  });
});
