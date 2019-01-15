import base from '../base';
import * as actions from './actions';
import mutations from './mutations';

export default () => ({
  ...base(),
  actions,
  mutations,
});
