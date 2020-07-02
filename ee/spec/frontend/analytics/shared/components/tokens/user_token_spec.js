import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
import UserToken from 'ee/analytics/shared/components/tokens/user_token.vue';
import { mockUsers } from './mock_data';

describe('UserToken', () => {
  let wrapper;
  let value;
  let config;
  let stubs;
  const defaultValue = { data: '' };

  const createComponent = (props = {}, options) => {
    wrapper = shallowMount(UserToken, {
      propsData: props,
      ...options,
    });
  };

  const findFilteredSearchSuggestion = index =>
    wrapper.findAll(GlFilteredSearchSuggestion).at(index);
  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllUserSuggestions = () => wrapper.findAll('[data-testid="user-item"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    value = defaultValue;
    config = {
      users: mockUsers,
      isLoading: false,
      fetchData: jest.fn(),
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

  describe('search', () => {
    describe('when no search term is given', () => {
      it('calls `fetchData` with an empty search term', () => {
        createComponent({
          config,
          value,
        });

        expect(config.fetchData).toHaveBeenCalledWith('');
      });
    });

    describe('when the search term "Diddy Kong" is given', () => {
      const data = 'Diddy Kong';
      it('calls `fetchData` with the search term', () => {
        createComponent({ config, value: { data } });

        expect(config.fetchData).toHaveBeenCalledWith(data);
      });
    });

    describe('when the input changes', () => {
      const data = 'Donkey Kong';
      it('calls `fetchData` with the updated search term', () => {
        createComponent({ config, value: defaultValue }, { stubs: { GlFilteredSearchToken } });
        expect(config.fetchData).not.toHaveBeenCalledWith(data);

        findFilteredSearchToken().vm.$emit('input', { data });
        expect(config.fetchData).toHaveBeenCalledWith(data);
      });
    });
  });
});
