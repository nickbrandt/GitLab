import base from '../base';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

export default () => ({
  ...base(),
  state: createState(),
  actions,
  mutations,
});
