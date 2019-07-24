import Vue from 'vue';
import Stats from 'ee_else_ce/stats';
import { shallowMount } from '@vue/test-utils';
import initNoteStats from 'ee_else_ce/event_tracking/notes';

describe('initNoteStats', () => {
  let wrapper;
  const createComponent = template => {
    const component = Vue.component('Notes', {
      name: 'Notes',
      template,
    });

    return shallowMount(component, { attachToDocument: true });
  };

  jest.mock('ee_else_ce/stats');
  Stats.trackEvent = jest.fn();
  Stats.bindTrackableContainer = jest.fn();

  afterEach(() => {
    Stats.trackEvent.mockClear();
    Stats.bindTrackableContainer.mockClear();
    wrapper.destroy();
  });

  describe('is a reply', () => {
    beforeEach(() => {
      wrapper = createComponent(
        "<div class='js-note-action-reply'><button class='main-notes-list'></button></div>",
      );
      initNoteStats();
    });

    it('calls bindTrackableContainer', () => {
      expect(Stats.bindTrackableContainer).toHaveBeenCalledTimes(1);
    });

    it('calls trackEvent', () => {
      wrapper.find('.main-notes-list').trigger('click');
      expect(Stats.trackEvent).toHaveBeenCalledTimes(1);
    });
  });

  describe('is not a reply', () => {
    it('does not call trackEvent', () => {
      wrapper = createComponent("<div><button class='main-notes-list'></button></div>");
      initNoteStats();
      wrapper.find('.main-notes-list').trigger('click');
      expect(Stats.trackEvent).not.toHaveBeenCalled();
    });
  });
});
