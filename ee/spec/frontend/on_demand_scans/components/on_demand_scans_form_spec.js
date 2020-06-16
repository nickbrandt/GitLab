import { shallowMount } from '@vue/test-utils';
import { GlForm } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import OnDemandScansForm from 'ee/on_demand_scans/components/on_demand_scans_form.vue';
import runDastScanMutation from 'ee/on_demand_scans/graphql/run_dast_scan.mutation.graphql';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';

const helpPagePath = `${TEST_HOST}/application_security/dast/index#on-demand-scans`;
const projectPath = 'group/project';
const defaultBranch = 'master';

const targetUrl = 'http://example.com';
const pipelineUrl = `${TEST_HOST}/${projectPath}/pipelines/123`;

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  isAbsolute: jest.requireActual('~/lib/utils/url_utility').isAbsolute,
  redirectTo: jest.fn(),
}));

describe('OnDemandScansApp', () => {
  let wrapper;

  const findForm = () => wrapper.find(GlForm);
  const findTargetUrlInput = () => wrapper.find('[data-testid="target-url-input"]');
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  const createComponent = ({ props = {}, computed = {} } = {}) => {
    wrapper = shallowMount(OnDemandScansForm, {
      attachToDocument: true,
      propsData: {
        helpPagePath,
        projectPath,
        defaultBranch,
        ...props,
      },
      computed,
      mocks: {
        $apollo: {
          mutate: jest.fn(),
        },
      },
    });
  };

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
          targetUrl: {
            value: targetUrl,
            state: null,
            feedback: '',
          },
        };
        expect(wrapper.vm.formData).toEqual({
          projectPath,
          targetUrl,
        });
      });
    });

    describe('formHasErrors', () => {
      it('returns true if any of the fields are invalid', () => {
        wrapper.vm.form = {
          targetUrl: {
            value: targetUrl,
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
          targetUrl: {
            value: targetUrl,
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
          targetUrl: {
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
          targetUrl: {
            value: targetUrl,
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

  describe('target URL input', () => {
    it.each(['asd', 'example.com'])('is marked as invalid provided an invalid URL', async value => {
      const input = findTargetUrlInput();
      input.vm.$emit('input', value);
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.form.targetUrl).toEqual({
        value,
        state: false,
        feedback: 'Please enter a valid URL format, ex: http://www.example.com/home',
      });
      expect(input.attributes().state).toBeUndefined();
    });

    it('is marked as valid provided a valid URL', async () => {
      const input = findTargetUrlInput();
      input.vm.$emit('input', targetUrl);
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.form.targetUrl).toEqual({
        value: targetUrl,
        state: true,
        feedback: null,
      });
      expect(input.attributes().state).toBe('true');
    });
  });

  describe('submission', () => {
    describe('on success', () => {
      beforeEach(async () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { runDastScan: { pipelineUrl } } });
        const input = findTargetUrlInput();
        input.vm.$emit('input', targetUrl);
        submitForm();
      });

      it('sets loading state', () => {
        expect(wrapper.vm.loading).toBe(true);
      });

      it('triggers GraphQL mutation', () => {
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: runDastScanMutation,
          variables: {
            scanType: 'PASSIVE',
            branch: 'master',
            targetUrl,
            projectPath,
          },
        });
      });

      it('redirects to the URL provided in the response', () => {
        expect(redirectTo).toHaveBeenCalledWith(pipelineUrl);
      });
    });

    describe('on error', () => {
      beforeEach(async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue();
        const input = findTargetUrlInput();
        input.vm.$emit('input', targetUrl);
        submitForm();
      });

      it('resets loading state', () => {
        expect(wrapper.vm.loading).toBe(false);
      });

      it('shows an error flash', () => {
        expect(createFlash).toHaveBeenCalledWith('Could not run the scan. Please try again.');
      });
    });
  });
});
