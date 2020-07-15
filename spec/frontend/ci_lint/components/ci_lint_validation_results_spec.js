import { mount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import CiLintValidationResults from '~/ci_lint/components/ci_lint_validation_results.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

import { builds, errors, jobs } from '../mock';

describe('CiLintValidationResults', () => {
  const successStatus = 'true';
  const failedStatus = 'false';

  const defaultProps = {
    builds,
    jobs,
    status: successStatus,
  };

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mount(CiLintValidationResults, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findAlertComponent = () => wrapper.find(GlAlert);
  const findLintErrorMessages = () => wrapper.find('[data-testid="lint-error-messages"]');
  const findAllJobCells = () => wrapper.findAll('[data-testid="lint-jobname"]');
  const findAllBeforeScriptBlocks = () => wrapper.findAll('[data-testid="lint-before-script"]');
  const findAllScriptBlocks = () => wrapper.findAll('[data-testid="lint-script"]');
  const findAllAfterScriptBlocks = () => wrapper.findAll('[data-testid="lint-after-script"]');
  const findAllList = () => wrapper.findAll('ul');

  describe('when the parsing fails', () => {
    beforeEach(() => {
      createWrapper({ status: failedStatus, errors });
    });

    it('renders an error banner', () => {
      expect(findAlertComponent().exists()).toBe(true);
      expect(findAlertComponent().text()).toBe('Status: syntax is incorrect');
    });

    it('renders a list of all the error messages', () => {
      expect(findLintErrorMessages().exists()).toBe(true);
      expect(findLintErrorMessages().text()).toMatch(errors.join(''));
    });
  });

  describe('when the parsing succeeds', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a success banner', () => {
      expect(findAlertComponent().exists()).toBe(true);
      expect(findAlertComponent().text()).toBe('Status: syntax is correct');
    });

    describe('it renders a table', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('with each job listed', () => {
        findAllJobCells().wrappers.forEach((w, i) => {
          const job = builds[i];
          const expectedString = `${capitalizeFirstCharacter(job.stage)} Job - ${job.name}`;

          return expect(w.text()).toBe(expectedString);
        });
      });

      it('with before_script values', () => {
        const values = findAllBeforeScriptBlocks().wrappers.map(w => w.text());
        const expectedValues = builds.map(build => build.options.before_script.join('\\n'));

        expect(values).toEqual(expectedValues);
      });

      it('with script values', () => {
        const values = findAllScriptBlocks().wrappers.map(w => w.text());
        const expectedValues = builds.map(build => build.options.script.join('\\n'));

        expect(values).toEqual(expectedValues);
      });

      it('with after_script values', () => {
        const values = findAllAfterScriptBlocks().wrappers.map(w => w.text());
        const expectedValues = builds.map(build => build.options.after_script.join('\\n'));

        expect(values).toEqual(expectedValues);
      });
    });
  });
});
