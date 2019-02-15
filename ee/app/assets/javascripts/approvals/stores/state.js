export const DEFAULT_SETTINGS = {
  canEdit: true,
  allowMultiRule: false,
};

export default (settings = {}) => ({
  settings: {
    ...DEFAULT_SETTINGS,
    ...settings,
  },
});
