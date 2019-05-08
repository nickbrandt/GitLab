import createDiff from './create_diff';

export const createMirror = () => {
  const uploadDiff = () => {
    // For now, this is a placeholder.
    // It will be implemented in https://gitlab.com/gitlab-org/gitlab-ee/issues/5276
  };

  return {
    upload(state) {
      uploadDiff(createDiff(state));
    },
  };
};

export default createMirror();
