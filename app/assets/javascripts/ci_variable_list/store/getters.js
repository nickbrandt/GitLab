import { extractEnvironmentScopes } from './utils';

export const joinedEnvironments = state => {
  if (state.variables) {
    const joined = state.environments.concat(extractEnvironmentScopes(state.variables));
    return [...new Set(joined)].sort();
  }
  return null;
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
