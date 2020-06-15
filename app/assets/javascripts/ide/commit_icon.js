import { commitItemIconMap } from './constants';

export default file => {
  if (file.modification === 'removed') {
    return commitItemIconMap.deleted;
  } else if (file.modification === 'addition') {
    return commitItemIconMap.addition;
  }

  return commitItemIconMap.modified;
};
