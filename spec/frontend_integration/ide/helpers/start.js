/* global monaco */

import { TEST_HOST } from 'helpers/test_constants';
import { projectData } from 'jest/ide/mock_data';
import { initIde } from '~/ide';
import extendStore from '~/ide/stores/extend';
import { IDE_DATASET } from './mock_data';

export default (container, { isRepoEmpty = false, path = '', mrId = '' } = {}) => {
  const projectName = isRepoEmpty ? 'lorem-ipsum-empty' : 'lorem-ipsum';
  const projectNamespaced = `gitlab-test/${projectName}`;
  const project = Object.assign({}, projectData, {
    path_with_namespace: projectNamespaced,
  });
  const pathSuffix = mrId ? `merge_requests/${mrId}` : `tree/master/-/${path}`;

  global.jsdom.reconfigure({
    url: `${TEST_HOST}/-/ide/project/${projectNamespaced}/${pathSuffix}`,
  });

  const el = document.createElement('div');
  Object.assign(el.dataset, {
    ...IDE_DATASET,
    project: JSON.stringify(project),
  });
  container.appendChild(el);
  const vm = initIde(el, { extendStore });

  // We need to dispose of editor Singleton things or tests will bump into eachother
  vm.$on('destroy', () => monaco.editor.getModels().forEach((model) => model.dispose()));

  return vm;
};
