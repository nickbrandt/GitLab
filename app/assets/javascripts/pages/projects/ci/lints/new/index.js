import CILintEditor from '../ci_lint_editor';
import initCILintResultResults from '~/ci_lint/index';

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new CILintEditor();
  initCILintResultResults();
});
