import { FS_ROOT_PATH } from '../../../constants';

export default () => ({
  // This is a hash object of the file path to a file object. Example:
  // - `files[""]` this will give you the root tree
  // - `files["README.md"]` this will give you the README blob
  files: {
    [FS_ROOT_PATH]: {
      timestamp: -1,
    },
  },
  loadedFiles: [],
});
