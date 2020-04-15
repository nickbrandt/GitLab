import { mount } from '@vue/test-utils';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';

describe('History Entry', () => {
  let wrapper;

  const note = {
    system: true,
    id: 123,
    note: 'changed vulnerability status to dismissed',
    system_note_icon_name: 'cancel',
    created_at: new Date().toISOString(),
    author: {
      name: 'author name',
      username: 'author username',
      status_tooltip_html: '<span class="status">status_tooltip_html</span>',
    },
  };

  const createWrapper = options => {
    wrapper = mount(HistoryEntry, {
      propsData: {
        discussion: {
          notes: [{ ...note, ...options }],
        },
      },
    });
  };

  const eventItem = () => wrapper.find(EventItem);

  afterEach(() => wrapper.destroy());

  it('passes the expected values to the event item component', () => {
    createWrapper();

    expect(eventItem().text()).toContain(note.note);
    expect(eventItem().props()).toMatchObject({
      id: note.id,
      author: note.author,
      createdAt: note.created_at,
      iconName: note.system_note_icon_name,
    });
  });

  it('does not render anything if there is no system note', () => {
    createWrapper({ system: false });
    expect(wrapper.html()).toBeFalsy();
  });
});
