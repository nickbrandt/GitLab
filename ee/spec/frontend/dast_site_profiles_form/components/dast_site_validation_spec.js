import merge from 'lodash/merge';
import { within } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import DastSiteValidation from 'ee/dast_site_profiles_form/components/dast_site_validation.vue';
import download from '~/lib/utils/downloader';

jest.mock('~/lib/utils/downloader');

// TODO: stop using fake timers once GraphQL mutations are implemented.
// See https://gitlab.com/gitlab-org/gitlab/-/issues/238578
jest.useFakeTimers();

const targetUrl = 'https://example.com/';
const token = 'validation-token-123';
const defaultProps = {
  targetUrl,
  token,
};

describe('DastSiteValidation', () => {
  let wrapper;

  const componentFactory = (mountFn = shallowMount) => options => {
    wrapper = mountFn(
      DastSiteValidation,
      merge(
        {},
        {
          propsData: defaultProps,
        },
        options,
      ),
    );
  };
  const createComponent = componentFactory();
  const createFullComponent = componentFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const findDownloadButton = () =>
    wrapper.find('[data-testid="download-dast-text-file-validation-button"]');
  const findValidateButton = () => wrapper.find('[data-testid="validate-dast-site-button"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createFullComponent();
    });

    it('renders properly', () => {
      expect(wrapper.html()).not.toBe('');
    });

    it('renders a download button containing the token', () => {
      const downloadButton = withinComponent().getByRole('button', {
        name: 'Download validation text file',
      });
      expect(downloadButton).not.toBeNull();
    });

    it('renders an input group with the target URL prepended', () => {
      const inputGroup = withinComponent().getByRole('group', {
        name: 'Step 3 - Confirm text file location and validate',
      });
      expect(inputGroup).not.toBeNull();
      expect(inputGroup.textContent).toContain(targetUrl);
    });
  });

  describe('text file validation', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking on the download button triggers a download of a text file containing the token', () => {
      findDownloadButton().vm.$emit('click');
      expect(download).toHaveBeenCalledWith({
        fileName: `GitLab-DAST-Site-Validation-${token}.txt`,
        fileData: btoa(token),
      });
    });
  });

  describe('validation', () => {
    beforeEach(() => {
      createComponent();
      findValidateButton().vm.$emit('click');
    });

    it('while validating, shows a loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(wrapper.text()).toContain('Validating...');
    });

    it('on success, emits success event', async () => {
      jest.spyOn(wrapper.vm, '$emit');
      jest.runAllTimers();
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('success');
    });

    // TODO: test error handling once GraphQL mutations are implemented.
    // See https://gitlab.com/gitlab-org/gitlab/-/issues/238578
    it.todo('on error, shows error state');
  });
});
