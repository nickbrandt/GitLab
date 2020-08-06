import { initIterationReport } from 'ee/iterations';
import { Namespace } from 'ee/iterations/constants';

document.addEventListener('DOMContentLoaded', () => {
  initIterationReport(Namespace.Project);
});
