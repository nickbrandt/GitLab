const isString = value => typeof value === 'string';

// eslint-disable-next-line import/prefer-default-export
export const isValidConfigurationEntity = object => {
  if (object == null) {
    return false;
  }

  const { field, type, description, label, defaultValue, value } = object;

  return (
    isString(field) &&
    isString(type) &&
    isString(description) &&
    isString(label) &&
    defaultValue !== undefined &&
    value !== undefined
  );
};
