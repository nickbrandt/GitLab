import { activityBarViews } from '../../../constants';

export const templateTypes = () => [
  {
    name: '.gitlab-ci.yml',
    key: 'gitlab_ci_ymls',
  },
  {
    name: '.gitignore',
    key: 'gitignores',
  },
  {
    name: 'LICENSE',
    key: 'licenses',
  },
  {
    name: 'Dockerfile',
    key: 'dockerfiles',
  },
  {
    name: '.gitlab/insights.yml',
    key: 'gitlab_insights_ymls'
  },
];

export const showFileTemplatesBar = (_, getters, rootState) => name =>
  getters.templateTypes.find(t => t.name === name) &&
  rootState.currentActivityView === activityBarViews.edit;

export default () => {};
