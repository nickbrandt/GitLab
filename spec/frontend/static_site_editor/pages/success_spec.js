import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import Success from '~/static_site_editor/pages/success.vue';
import { savedContentMeta, returnUrl, sourcePath } from '../mock_data';
import { HOME_ROUTE } from '~/static_site_editor/router/constants';

describe('static_site_editor/pages/success', () => {
  const mergeRequestsIllustrationPath = 'illustrations/merge_requests.svg';
  let wrapper;
  let router;

  const buildRouter = () => {
    router = {
      push: jest.fn(),
    };
  };

  const buildWrapper = (data = {}) => {
    wrapper = shallowMount(Success, {
      mocks: {
        $router: router,
      },
      stubs: {
        GlEmptyState,
        GlButton,
      },
      propsData: {
        mergeRequestsIllustrationPath,
      },
      data() {
        return {
          savedContentMeta,
          appData: {
            returnUrl,
            sourcePath,
          },
          ...data,
        };
      },
    });
  };

  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findReturnUrlButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    buildRouter();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders empty state with a link to the created merge request', () => {
    buildWrapper();

    expect(findEmptyState().exists()).toBe(true);
    expect(findEmptyState().props()).toMatchObject({
      primaryButtonText: 'View merge request',
      primaryButtonLink: savedContentMeta.mergeRequest.url,
      title: 'Your merge request is ready to be managed',
      svgPath: mergeRequestsIllustrationPath,
    });
  });

  it('displays merge request instructions in the empty state', () => {
    buildWrapper();

    expect(findEmptyState().text()).toContain(
      'A couple of things you need to do to get your changes visible:',
    );
    expect(findEmptyState().text()).toContain(
      '1. Add a description to this merge request to explain why the change is being made.',
    );
    expect(findEmptyState().text()).toContain(
      '2. Assign this merge request to a person who can accept the changes so that it can be visible on the site.',
    );
  });

  it('displays return to site button', () => {
    buildWrapper();

    expect(findReturnUrlButton().text()).toBe('Return to site');
    expect(findReturnUrlButton().attributes().href).toBe(returnUrl);
  });

  it('displays source path', () => {
    buildWrapper();

    expect(wrapper.text()).toContain(`Update ${sourcePath} file`);
  });

  it('redirects to the HOME route when content has not been submitted', () => {
    buildWrapper({ savedContentMeta: null });

    expect(router.push).toHaveBeenCalledWith(HOME_ROUTE);
    expect(wrapper.html()).toBe('');
  });
});
