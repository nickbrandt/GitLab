import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import PackageListApp from 'ee/packages/list/components/packages_list_app.vue';

describe('packages_list_app', () => {
  let wrapper;
  const emptyListHelpUrl = 'helpUrl';
  const findGlEmptyState = (w = wrapper) => w.find({ name: 'gl-empty-state-stub' });

  beforeEach(() => {
    wrapper = shallowMount(PackageListApp, {
      propsData: {
        projectId: '1',
        emptyListIllustration: 'helpSvg',
        emptyListHelpUrl,
      },
      stubs: {
        'package-list': '<div><slot name="empty-state"></slot></div>',
        GlEmptyState: { ...GlEmptyState, name: 'gl-empty-state-stub' },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('generate the correct empty list link', () => {
    const emptyState = findGlEmptyState();
    const link = emptyState.find('a');

    expect(link.html()).toMatchInlineSnapshot(
      `"<a href=\\"${emptyListHelpUrl}\\" target=\\"_blank\\">publish and share your packages</a>"`,
    );
  });
});
