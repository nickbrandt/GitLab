import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/event_item.vue';
import mountComponent from 'helpers/vue_mount_component_helper';

describe('Event Item', () => {
  const Component = Vue.extend(component);
  const props = {
    author: {
      name: 'Tanuki',
      username: 'gitlab',
    },
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  beforeEach(() => {
    vm = mountComponent(Component, props);
  });

  it('uses the author name', () => {
    expect(vm.$el.querySelector('.js-author').textContent).toContain(props.author.name);
  });

  it('uses the author username', () => {
    expect(vm.$el.querySelector('.js-author').textContent).toContain(`@${props.author.username}`);
  });

  it('uses the fallback icon', () => {
    expect(vm.iconName).toBe('plus');
  });

  it('uses the fallback icon class', () => {
    expect(vm.iconStyle).toBe('ci-status-icon-success');
  });
});
