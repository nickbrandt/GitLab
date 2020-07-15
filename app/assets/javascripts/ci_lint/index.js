import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import CiLintValidationResults from './components/ci_lint_validation_results.vue';

Vue.use(Translate);

export const createCiLintValidationResults = () => {
  const el = document.querySelector('#js-ci-lint-validation');
  const { builds, errors, status } = el?.dataset;

  // eslint-disable-next-line no-new
  return new Vue({
    el,
    components: {
      CiLintValidationResults,
    },
    render(createElement) {
      return createElement('ci-lint-validation-results', {
        props: {
          builds: JSON.parse(builds),
          errors: JSON.parse(errors),
          status,
        },
      });
    },
  });
};

export default () => {
  createCiLintValidationResults();
};
