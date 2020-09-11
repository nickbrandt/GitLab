import { createWrapper } from '@vue/test-utils';
import initGroupMembersApp from '~/groups/members';
import GroupMembersApp from '~/groups/members/components/app.vue';
import { membersJsonString, membersParsed } from './mock_data';

describe('initGroupMembersApp', () => {
  let el;
  let vm;
  let wrapper;

  const setup = () => {
    vm = initGroupMembersApp(el);
    wrapper = createWrapper(vm);
  };

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-members', membersJsonString);
    el.setAttribute('data-current-user-id', '123');
    el.setAttribute('data-group-id', '234');

    document.body.appendChild(el);
  });

  afterEach(() => {
    document.body.innerHTML = '';
    el = null;

    wrapper.destroy();
    wrapper = null;
  });

  it('renders `GroupMembersApp`', () => {
    setup();

    expect(wrapper.find(GroupMembersApp).exists()).toBe(true);
  });

  it('parses and sets `currentUserId` in Vuex store', () => {
    setup();

    expect(vm.$store.state.currentUserId).toBe(123);
  });

  describe('when `data-current-user-id` is not set (user is not logged in)', () => {
    it('sets `currentUserId` as `null` in Vuex store', () => {
      el.removeAttribute('data-current-user-id');
      setup();

      expect(vm.$store.state.currentUserId).toBeNull();
    });
  });

  it('parses and sets `data-group-id` as `sourceId` in Vuex store', () => {
    setup();

    expect(vm.$store.state.sourceId).toBe(234);
  });

  it('parses and sets `members` in Vuex store', () => {
    setup();

    expect(vm.$store.state.members).toEqual(membersParsed);
  });
});
