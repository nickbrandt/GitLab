import Component from 'ee/vue_shared/security_reports/components/event_item.vue';
import { shallowMount, mount } from '@vue/test-utils';

describe('Event Item', () => {
  describe('initial state', () => {
    let wrapper;

    const propsData = {
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
    };

    afterEach(() => {
      wrapper.destroy();
    });

    beforeEach(() => {
      wrapper = shallowMount(Component, { propsData });
    });

    it('uses the author name', () => {
      expect(wrapper.find('.js-author').text()).toContain(propsData.author.name);
    });

    it('uses the author username', () => {
      expect(wrapper.find('.js-author').text()).toContain(`@${propsData.author.username}`);
    });

    it('uses the fallback icon', () => {
      expect(wrapper.props().iconName).toBe('plus');
    });

    it('uses the fallback icon class', () => {
      expect(wrapper.props().iconStyle).toBe('ci-status-icon-success');
    });

    it('renders the action buttons tontainer', () => {
      expect(wrapper.find('.action-buttons')).toExist();
    });
  });
  describe('with action buttons', () => {
    let wrapper;

    const propsData = {
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
      actionButtons: [
        {
          iconName: 'pencil',
          emit: 'fooEvent',
          title: 'Foo Action',
        },
        {
          iconName: 'remove',
          emit: 'barEvent',
          title: 'Bar Action',
        },
      ],
    };

    afterEach(() => {
      wrapper.destroy();
    });

    beforeEach(() => {
      wrapper = mount(Component, { propsData });
    });

    it('renders the action buttons container', () => {
      expect(wrapper.find('.action-buttons')).toExist();
    });

    it('renders the action buttons', () => {
      expect(wrapper.findAll('.action-buttons > button').length).toBe(2);
      expect(wrapper).toMatchSnapshot();
    });

    it('emits the button events when clicked', () => {
      const buttons = wrapper.findAll('.action-buttons > button');
      buttons.at(0).trigger('click');
      buttons.at(1).trigger('click');

      expect(wrapper.emitted().fooEvent.length).toEqual(1);
      expect(wrapper.emitted().barEvent.length).toEqual(1);
    });
  });
});
