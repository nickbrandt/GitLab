import Vue from 'vue';
import Tracking from '~/tracking';
import { shallowMount } from '@vue/test-utils';
import initNoteStats from 'ee_else_ce/event_tracking/notes';

jest.mock('~/tracking');

describe('initNoteStats', () => {
  let wrapper;
  const createComponent = template => {
    const component = Vue.component('Notes', {
      name: 'Notes',
      template,
    });

    return shallowMount(component, { attachToDocument: true });
  };

  afterEach(() => {
    jest.clearAllMocks();
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
      expect(Tracking.prototype.bind).toHaveBeenCalledTimes(1);
    });

    it('calls trackEvent', () => {
      wrapper.find('.main-notes-list').trigger('click');
      expect(Tracking.event).toHaveBeenCalledTimes(1);
    });
  });

  describe('is not a reply', () => {
    it('does not call trackEvent', () => {
      wrapper = createComponent("<div><button class='main-notes-list'></button></div>");
      initNoteStats();
      wrapper.find('.main-notes-list').trigger('click');
      expect(Tracking.event).not.toHaveBeenCalled();
    });
  });
});
