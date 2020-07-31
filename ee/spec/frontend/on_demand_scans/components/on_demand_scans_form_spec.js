import { merge } from 'lodash';
import { mount, shallowMount } from '@vue/test-utils';
import { GlForm, GlSkeletonLoader } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import OnDemandScansForm from 'ee/on_demand_scans/components/on_demand_scans_form.vue';
import dastOnDemandScanCreate from 'ee/on_demand_scans/graphql/dast_on_demand_scan_create.mutation.graphql';
import { redirectTo } from '~/lib/utils/url_utility';

const helpPagePath = `${TEST_HOST}/application_security/dast/index#on-demand-scans`;
const projectPath = 'group/project';
const defaultBranch = 'master';
const profilesLibraryPath = `${TEST_HOST}/${projectPath}/-/on_demand_scans/profiles`;
const newSiteProfilePath = `${TEST_HOST}/${projectPath}/-/on_demand_scans/profiles`;

const defaultProps = {
  helpPagePath,
  projectPath,
  defaultBranch,
  profilesLibraryPath,
  newSiteProfilePath,
};

const siteProfiles = [
  { id: 1, profileName: 'My first site profile', targetUrl: 'https://example.com' },
  { id: 2, profileName: 'My second site profile', targetUrl: 'https://foo.bar' },
];
const pipelineUrl = `${TEST_HOST}/${projectPath}/pipelines/123`;

jest.mock('~/lib/utils/url_utility', () => ({
  isAbsolute: jest.requireActual('~/lib/utils/url_utility').isAbsolute,
  redirectTo: jest.fn(),
}));

describe('OnDemandScansApp', () => {
  let wrapper;

  const findForm = () => wrapper.find(GlForm);
  const findSiteProfilesDropdown = () => wrapper.find('[data-testid="site-profiles-dropdown"]');
  const findManageSiteProfilesButton = () =>
    wrapper.find('[data-testid="manage-site-profiles-button"]');
  const findCreateNewSiteProfileLink = () =>
    wrapper.find('[data-testid="create-site-profile-link"]');
  const findAlert = () => wrapper.find('[data-testid="on-demand-scan-error"]');
  const findCancelButton = () => wrapper.find('[data-testid="on-demand-scan-cancel-button"]');
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  const wrapperFactory = (mountFn = shallowMount) => (options = {}) => {
    wrapper = mountFn(
      OnDemandScansForm,
      merge(
        {},
        {
          propsData: defaultProps,
          mocks: {
            $apollo: {
              mutate: jest.fn(),
              queries: {
                siteProfiles: {},
              },
            },
          },
        },
        options,
        {
          data() {
            return { ...options.data };
          },
        },
      ),
    );
  };
  const createComponent = wrapperFactory();
  const createFullComponent = wrapperFactory(mount);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders properly', () => {
    expect(wrapper.isVueInstance()).toBe(true);
  });

  describe('computed props', () => {
    describe('formData', () => {
      it('returns an object with a key:value mapping from the form object including the project path', () => {
        wrapper.vm.form = {
          siteProfileId: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
        };
        expect(wrapper.vm.formData).toEqual({
          fullPath: projectPath,
          siteProfileId: siteProfiles[0],
        });
      });
    });

    describe('formHasErrors', () => {
      it('returns true if any of the fields are invalid', () => {
        wrapper.vm.form = {
          siteProfileId: {
            value: siteProfiles[0],
            state: false,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.formHasErrors).toBe(true);
      });

      it('returns false if none of the fields are invalid', () => {
        wrapper.vm.form = {
          siteProfileId: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.formHasErrors).toBe(false);
      });
    });

    describe('someFieldEmpty', () => {
      it('returns true if any of the fields are empty', () => {
        wrapper.vm.form = {
          siteProfileId: {
            value: '',
            state: false,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.someFieldEmpty).toBe(true);
      });

      it('returns false if no field is empty', () => {
        wrapper.vm.form = {
          siteProfileId: {
            value: siteProfiles[0],
            state: null,
            feedback: '',
          },
          foo: {
            value: 'bar',
            state: null,
          },
        };
        expect(wrapper.vm.someFieldEmpty).toBe(false);
      });
    });

    describe('isSubmitDisabled', () => {
      it.each`
        formHasErrors | someFieldEmpty | expected
        ${true}       | ${true}        | ${true}
        ${true}       | ${false}       | ${true}
        ${false}      | ${true}        | ${true}
        ${false}      | ${false}       | ${false}
      `(
        'is $expected when formHasErrors is $formHasErrors and someFieldEmpty is $someFieldEmpty',
        ({ formHasErrors, someFieldEmpty, expected }) => {
          createComponent({
            computed: {
              formHasErrors: () => formHasErrors,
              someFieldEmpty: () => someFieldEmpty,
            },
          });

          expect(wrapper.vm.isSubmitDisabled).toBe(expected);
        },
      );
    });
  });

  describe('site profiles', () => {
    describe('while site profiles are being fetched', () => {
      beforeEach(() => {
        createComponent({ mocks: { $apollo: { queries: { siteProfiles: { loading: true } } } } });
      });

      it('shows a skeleton loader', () => {
        expect(wrapper.contains(GlSkeletonLoader)).toBe(true);
      });
    });

    describe('when site profiles could not be fetched', () => {
      beforeEach(() => {
        createComponent();
        return wrapper.vm.showErrors('ERROR_FETCH_SITE_PROFILES');
      });

      it('shows a non-dismissible alert and no field', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.props('dismissible')).toBe(false);
        expect(alert.text()).toContain('Could not fetch site profiles. Please try again.');
      });
    });

    describe('when there are no site profiles yet', () => {
      beforeEach(() => {
        createFullComponent();
      });

      it('disables the link to manage site profiles', () => {
        expect(findManageSiteProfilesButton().props('disabled')).toBe(true);
      });

      it('shows a link to create a new site profile', () => {
        const link = findCreateNewSiteProfileLink();
        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe(newSiteProfilePath);
      });
    });

    describe('when there are site profiles', () => {
      beforeEach(() => {
        createComponent({
          data: {
            siteProfiles,
          },
        });
      });

      it('shows a dropdown containing the site profiles', () => {
        const dropdown = findSiteProfilesDropdown();
        expect(dropdown.exists()).toBe(true);
        expect(dropdown.element.children).toHaveLength(siteProfiles.length);
      });

      it('when a site profile is selected, its summary is displayed below the dropdown', async () => {
        wrapper.vm.form.dastSiteProfileId.value = siteProfiles[0].id;
        await wrapper.vm.$nextTick();
        const summary = wrapper.find('[data-testid="site-profile-summary"]');

        expect(summary.exists()).toBe(true);
        expect(summary.text()).toContain(siteProfiles[0].targetUrl);
      });
    });
  });

  describe('submission', () => {
    beforeEach(() => {
      createComponent({
        data: {
          siteProfiles,
        },
      });
    });

    describe('on success', () => {
      beforeEach(() => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { dastOnDemandScanCreate: { pipelineUrl, errors: [] } } });
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('sets loading state', () => {
        expect(wrapper.vm.loading).toBe(true);
      });

      it('triggers GraphQL mutation', () => {
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: dastOnDemandScanCreate,
          variables: {
            scanType: 'PASSIVE',
            branch: 'master',
            dastSiteProfileId: siteProfiles[0],
            fullPath: projectPath,
          },
        });
      });

      it('redirects to the URL provided in the response', () => {
        expect(redirectTo).toHaveBeenCalledWith(pipelineUrl);
      });

      it('does not show an alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('on top-level error', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue();
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain('Could not run the scan. Please try again.');
      });
    });

    describe('on errors as data', () => {
      const errors = ['error#1', 'error#2', 'error#3'];

      beforeEach(() => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { dastOnDemandScanCreate: { pipelineUrl: null, errors } } });
        findSiteProfilesDropdown().vm.$emit('input', siteProfiles[0]);
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an alert with the returned errors', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        errors.forEach(error => {
          expect(alert.text()).toContain(error);
        });
      });
    });
  });

  describe('cancel', () => {
    it('emits cancel event on click', () => {
      jest.spyOn(wrapper.vm, '$emit');
      findCancelButton().vm.$emit('click');

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('cancel');
    });
  });
});
