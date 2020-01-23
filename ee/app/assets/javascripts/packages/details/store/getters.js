export default ({ packageEntity }) => {
  // eslint-disable-next-line camelcase
  if (packageEntity?.build_info?.pipeline_id) {
    return true;
  }

  return false;
};
