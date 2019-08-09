import { shallowMount } from '@vue/test-utils';
import DesignNote from 'ee/design_management/components/design_notes/design_note.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Design note component', () => {
  let wrapper;

  const findUserAvatar = () => wrapper.find(UserAvatarLink);
  const findUserLink = () => wrapper.find('.js-user-link');

  function createComponent(props = {}) {
    wrapper = shallowMount(DesignNote, {
      sync: false,
      propsData: {
        note: {},
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render an author', () => {
    createComponent({
      note: {
        author: {
          id: 'author-id',
        },
      },
    });

    expect(findUserAvatar().exists()).toBe(true);
    expect(findUserLink().exists()).toBe(true);
  });

  it('should render a time ago tooltip if note has createdAt property', () => {
    createComponent({
      note: {
        createdAt: '2019-07-26T15:02:20Z',
        author: {
          id: 'author-id',
        },
      },
    });

    expect(wrapper.find(TimeAgoTooltip).exists()).toBe(true);
  });
});
