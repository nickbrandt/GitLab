import Vue from 'vue';
import IssueCardWeight from 'ee/boards/components/issue_card_weight.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('IssueCardWeight component', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(IssueCardWeight);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders weight', () => {
    vm = mountComponent(Component, {
      weight: 5,
    });

    expect(vm.$el.querySelector('.board-card-info-text')).toContainText('5');
  });

  it('renders a link when no tag is specified', () => {
    vm = mountComponent(Component, {
      weight: 2,
    });

    expect(vm.$el.querySelector('a.board-card-info')).toBeDefined();
  });

  it('renders the tag when it is explicitly specified', () => {
    vm = mountComponent(Component, {
      weight: 2,
      tagName: 'span',
    });

    expect(vm.$el.querySelector('span.board-card-info')).toBeDefined();
    expect(vm.$el.querySelector('a.board-card-info')).toBeNull();
  });
});
