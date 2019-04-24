import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/split_button.vue';
import mountComponent from 'helpers/vue_mount_component_helper';

describe('Split Button', () => {
  const Component = Vue.extend(component);
  const buttons = [
    {
      name: 'button one',
      tagline: "button one's tagline",
      isLoading: false,
      action: 'button1Action',
    },
    {
      name: 'button two',
      tagline: "button two's tagline",
      isLoading: false,
      action: 'button2Action',
    },
    {
      name: 'button three',
      tagline: "button three's tagline",
      isLoading: true,
      action: 'button3Action',
    },
  ];
  let props;
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with two buttons', () => {
    beforeEach(() => {
      props = { buttons: buttons.slice(0, 2) };
      vm = mountComponent(Component, props);
    });

    it('renders two dropdown items', () => {
      expect(vm.$el.querySelectorAll('.dropdown-item')).toHaveLength(2);
    });

    it('displays the first button initially', () => {
      expect(vm.$el.querySelector('.btn').textContent.trim()).toBe(buttons[0].name);
    });

    it('emits the correct event when the button is pressed', () => {
      jest.spyOn(vm, '$emit');

      vm.$el.querySelector('.btn').click();

      expect(vm.$emit).toHaveBeenCalledWith(buttons[0].action);
    });
  });

  describe('with three buttons', () => {
    beforeEach(() => {
      props = { buttons };
      vm = mountComponent(Component, props);
    });

    it('renders three dropdown items', () => {
      expect(vm.$el.querySelectorAll('.dropdown-item')).toHaveLength(3);
    });
  });
});
