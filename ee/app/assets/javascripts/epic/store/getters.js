import { statusType } from '../constants';

export const isEpicOpen = state => state.state === statusType.open;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
