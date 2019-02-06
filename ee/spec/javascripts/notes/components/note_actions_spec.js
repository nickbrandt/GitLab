import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { TEST_HOST } from 'spec/test_constants';
import { userDataMock } from 'spec/notes/mock_data';

describe('noteActions', () => {
  let wrapper;
  let store;
  let props;

  const createWrapper = propsData => {
    const localVue = createLocalVue();
    return shallowMount(noteActions, {
      store,
      propsData,
      localVue,
      sync: false,
    });
  };

  beforeEach(() => {
    store = createStore();
    props = {
      accessLevel: 'Maintainer',
      authorId: 26,
      canDelete: true,
      canEdit: true,
      canAwardEmoji: true,
      canReportAsAbuse: true,
      noteId: '539',
      noteUrl: `${TEST_HOST}/group/project/merge_requests/1#note_1`,
      reportAbusePath: `${TEST_HOST}/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26`,
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
      expect(wrapper.vm.resolveButtonTitle).toEqual('Discussion stays unresolved');
    });
  });
});
