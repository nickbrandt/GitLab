export const DEFAULT_SETTINGS = {
  canEdit: true,
};

export default (settings = {}) => ({
  settings: {
    ...DEFAULT_SETTINGS,
    ...settings,
  },
  isLoading: false,
  rules: [],
});
