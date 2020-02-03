export default ({ packageEntity }) => {
  if (packageEntity?.build_info?.pipeline_id) {
    return true;
  }

  return false;
};
