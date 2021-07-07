import { GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

const defaultProps = {
  projectName: 'GitLab',
};

describe('ProjectAvatar', () => {
  let wrapper;

  const findGlAvatar = () => wrapper.findComponent(GlAvatar);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(ProjectAvatar, { propsData: { ...defaultProps, ...props } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders GlAvatar with correct props', () => {
    createComponent();

    const avatar = findGlAvatar();
    expect(avatar.exists()).toBe(true);
    expect(avatar.props()).toMatchObject({
      alt: defaultProps.projectName,
      entityName: defaultProps.projectName,
      size: 32,
      src: '',
    });
  });

  describe('with `size` prop', () => {
    it('renders GlAvatar with specified `size` prop', () => {
      const mockSize = 48;
      createComponent({ props: { size: mockSize } });

      const avatar = findGlAvatar();
      expect(avatar.props('size')).toBe(mockSize);
    });
  });

  describe('with `projectAvatarUrl` prop', () => {
    it('renders GlAvatar with specified `src` prop', () => {
      const mockProjectAvatarUrl = 'https://gitlab.com';
      createComponent({ props: { projectAvatarUrl: mockProjectAvatarUrl } });

      const avatar = findGlAvatar();
      expect(avatar.props('src')).toBe(mockProjectAvatarUrl);
    });
  });
});
