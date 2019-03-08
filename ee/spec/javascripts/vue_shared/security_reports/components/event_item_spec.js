import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/event_item.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Event Item', () => {
  const Component = Vue.extend(component);
  const props = {
    authorName: 'Tanuki',
    authorUsername: 'gitlab',
    actionLinkText: 'foo',
    actionLinkUrl: 'example.com',
  };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('issue item', () => {
    beforeEach(() => {
      props.type = 'issue';
      vm = mountComponent(Component, props);
    });

    it('uses the issue icon', () => {
      expect(vm.iconName).toBe('issue-created');
    });

    it('uses the issue name', () => {
      expect(vm.$el.querySelector('.js-created').textContent).toContain('issue');
    });

    it('uses the author name', () => {
      expect(vm.$el.querySelector('.js-author-name').textContent).toContain(props.authorName);
    });

    it('uses the author username', () => {
      expect(vm.$el.querySelector('.js-username').textContent).toContain(props.authorUsername);
    });

    it('uses the action link text', () => {
      expect(vm.$el.querySelector('.js-action-link').textContent).toContain(props.actionLinkText);
    });

    it('uses the action link url', () => {
      expect(vm.$el.querySelector('.js-action-link').getAttribute('href')).toBe(
        props.actionLinkUrl,
      );
    });
  });

  describe('merge request item', () => {
    beforeEach(() => {
      props.type = 'mergeRequest';
      vm = mountComponent(Component, props);
    });

    it('uses the merge request icon', () => {
      expect(vm.iconName).toBe('merge-request');
    });

    it('uses the issue name', () => {
      expect(vm.$el.querySelector('.js-created').textContent).toContain('merge request');
    });
  });

  describe('unknown item', () => {
    beforeEach(() => {
      props.type = 'notARealType';
      vm = mountComponent(Component, props);
    });

    it('uses the fallback icon', () => {
      expect(vm.iconName).toBe('plus');
    });

    it("doesn't display the created text", () => {
      expect(vm.$el.querySelector('.js-created')).toBeNull();
    });
  });
});
