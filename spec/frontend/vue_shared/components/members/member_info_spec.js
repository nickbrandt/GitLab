import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import { GlAvatarLink } from '@gitlab/ui';
import MemberInfo from '~/vue_shared/components/members/member_info.vue';
import { member, group, invited } from './mock_data';

describe('MemberList', () => {
  let wrapper;

  const createComponent = propsData => {
    wrapper = mount(MemberInfo, {
      propsData,
    });
  };

  const findLink = () => wrapper.find(GlAvatarLink);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('User', () => {
    beforeEach(() => {
      createComponent({ member });
    });

    it("renders link to user's profile", () => {
      const link = findLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('https://gitlab.com/root');
      expect(link.attributes('data-user-id')).toBe('123');
      expect(link.attributes('data-username')).toBe('root');
    });

    it("renders user's name", () => {
      expect(getByText(wrapper.element, 'Administrator')).not.toBe(null);
    });

    it("renders user's username", () => {
      expect(getByText(wrapper.element, '@root')).not.toBe(null);
    });
  });

  describe('Group', () => {
    beforeEach(() => {
      createComponent({ member: group });
    });

    it('renders link to group', () => {
      const link = findLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('https://gitlab.com/groups/Commit451');
    });

    it("renders group's name", () => {
      expect(getByText(wrapper.element, 'Commit451')).not.toBe(null);
    });
  });

  describe('Invited', () => {
    beforeEach(() => {
      createComponent({ member: invited });
    });

    it('renders email as name', () => {
      expect(getByText(wrapper.element, 'jewel@hudsonwalter.biz')).not.toBe(null);
    });
  });
});
