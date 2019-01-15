import createState from './state';
import * as getters from './getters';
import mutations from './mutations';

export default () => ({
  state: createState(),
  getters,
  mutations,
});
