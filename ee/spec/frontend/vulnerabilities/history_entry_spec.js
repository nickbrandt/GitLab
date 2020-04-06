import { shallowMount } from '@vue/test-utils';
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';

describe('History Entry', () => {
  let wrapper;

  const note = {
    system: true,
    note: 'changed vulnerability status to dismissed',
    system_note_icon_name: 'cancel',
    created_at: 'created_at_timestamp',
    author: {
      name: 'author name',
      username: 'author username',
      status_tooltip_html: '<span class="status">status_tooltip_html</span>',
    },
  };

  const createWrapper = options => {
    wrapper = shallowMount(HistoryEntry, {
      propsData: {
        discussion: {
          notes: [{ ...note, ...options }],
        },
      },
    });
  };

  const icon = () => wrapper.find(Icon);
  const authorName = () => wrapper.find({ ref: 'authorName' });
  const authorUsername = () => wrapper.find({ ref: 'authorUsername' });
  const authorStatus = () => wrapper.find({ ref: 'authorStatus' });
  const stateChangeMessage = () => wrapper.find({ ref: 'stateChangeMessage' });
  const timeAgoTooltip = () => wrapper.find(TimeAgoTooltip);

  afterEach(() => wrapper.destroy());

  describe('default wrapper tests', () => {
    beforeEach(() => createWrapper());

    it('shows the correct icon', () => {
      expect(icon().exists()).toBe(true);
      expect(icon().attributes('name')).toBe(note.system_note_icon_name);
    });

    it('shows the correct user', () => {
      expect(authorName().text()).toBe(note.author.name);
      expect(authorUsername().text()).toBe(`@${note.author.username}`);
    });

    it('shows the correct status if the user has a status set', () => {
      expect(authorStatus().exists()).toBe(true);
      expect(authorStatus().element.innerHTML).toBe(note.author.status_tooltip_html);
    });

    it('shows the state change message', () => {
      expect(stateChangeMessage().text()).toBe(note.note);
    });

    it('shows the time ago tooltip', () => {
      expect(timeAgoTooltip().exists()).toBe(true);
      expect(timeAgoTooltip().attributes('time')).toBe(note.created_at);
    });
  });

  describe('custom wrapper tests', () => {
    it('does not show the user status if user has no status set', () => {
      createWrapper({ author: { status_tooltip_html: undefined } });
      expect(authorStatus().exists()).toBe(false);
    });

    it('does not render anything if there is no system note', () => {
      createWrapper({ system: false });
      expect(wrapper.html()).toBeFalsy();
    });
  });
});
