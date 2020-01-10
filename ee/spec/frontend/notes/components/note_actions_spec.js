import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import createStore from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { userDataMock } from '../../../../spec/frontend/notes/mock_data';

describe('noteActions', () => {
  let wrapper;
  let store;
  let props;

  const createWrapper = propsData =>
    shallowMount(noteActions, {
      store,
      propsData,
      attachToDocument: true,
    });

  beforeEach(() => {
    store = createStore();
    props = {
      accessLevel: 'Maintainer',
      authorId: 26,
      canDelete: true,
      canEdit: true,
      canAwardEmoji: true,
      canReportAsAbuse: true,
      canResolve: true,
      noteId: '539',
      noteUrl: `${TEST_HOST}/group/project/merge_requests/1#note_1`,
      reportAbusePath: `${TEST_HOST}/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-foss%2Fissues%2F7%23note_539&user_id=26`,
      showReply: false,
      isDraft: true,
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Draft notes', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = createWrapper(props);
    });

    it('should render the right resolve button title', () => {
      const resolveButton = wrapper.find({ ref: 'resolveButton' });

      expect(resolveButton.exists()).toBe(true);
      expect(resolveButton.attributes('title')).toEqual('Thread stays unresolved');
    });
  });
});
