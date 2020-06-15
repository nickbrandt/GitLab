export default () => ({
  objects: {},
  refs: {
    head: '',
    fs: '',
  },
  // lastTimestamp - this one is needed so that we have a checkpoint for where to start looking for filesystem changes
  lastTimestamp: -1,
  // isCleaning - This one might not be needed, but is meant to be used as a gate that we shouldn't update objects if we're in the middle of cleaning them.
  isCleaning: false,
  // status - if this is empty, there is no difference between head and fs. Otherwise, this contains a list of { path, headObjId, modification }
  status: [],
});
