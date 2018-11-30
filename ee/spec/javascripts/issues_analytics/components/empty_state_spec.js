import Vue from 'vue';
import EmptyState from 'ee/issues_analytics/components/empty_state.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Empty state component', () => {
  let vm;
  const Component = Vue.extend(EmptyState);
  const props = {
    image: 'illustrations/issues.svg',
    title: 'Hello World',
    summary: 'Lorem, ipsum dolor sit amet consectetur adipisicing elit.',
  };

  beforeEach(() => {
    vm = mountComponent(Component, props);
  });

  it('renders the image', () => {
    expect(vm.$el.querySelector('.content-image').src).toContain(props.image);
  });

  it('renders the title', () => {
    expect(vm.$el.querySelector('.content-title').textContent.trim()).toEqual(props.title);
  });

  it('renders the summary', () => {
    expect(vm.$el.querySelector('.content-summary').textContent.trim()).toEqual(props.summary);
  });
});
