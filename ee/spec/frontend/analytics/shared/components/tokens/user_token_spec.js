import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import UserToken from 'ee/analytics/shared/components/tokens/user_token.vue';
import { mockUsers } from './mock_data';

describe('UserToken', () => {
  let wrapper;
  let value;
  let config;
  let stubs;

  const createComponent = (props = {}, options) => {
    wrapper = shallowMount(UserToken, {
      propsData: props,
      ...options,
    });
  };

  const findFilteredSearchSuggestion = index =>
    wrapper.findAll(GlFilteredSearchSuggestion).at(index);
  const findAllUserSuggestions = () => wrapper.findAll('[data-testid="user-item"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    value = { data: '' };
    config = {
      users: mockUsers,
      isLoading: false,
    };
    stubs = {
      GlFilteredSearchToken: {
        template: `<div><slot name="view"></slot><slot name="suggestions"></slot></div>`,
      },
    };
  });

  it('renders a loading icon', () => {
    config.isLoading = true;

    createComponent({ config, value: {} }, { stubs });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders the selected user', () => {
    const selectedUser = mockUsers[1];
    createComponent(
      {
        config,
        value: {
          data: selectedUser.username,
        },
      },
      { stubs },
    );

    const avatar = wrapper.find('[data-testid="selected-user"]').find('gl-avatar-stub');
    expect(avatar.props('src')).toBe(selectedUser.avatar_url);
  });

  describe('suggestions', () => {
    it('renders the username and user name for each user', () => {
      createComponent({ config, value }, { stubs });
      mockUsers.forEach((user, index) => {
        const text = `${user.name} @${user.username}`;
        expect(findFilteredSearchSuggestion(index).text()).toEqual(text);
      });
    });

    it('renders all user suggestions', () => {
      createComponent({ config, value }, { stubs });

      expect(findAllUserSuggestions()).toHaveLength(3);
    });
  });
});
