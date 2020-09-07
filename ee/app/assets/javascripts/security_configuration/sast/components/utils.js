const isString = value => typeof value === 'string';
const isBoolean = value => typeof value === 'boolean';

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

export const isValidAnalyzerEntity = object => {
  if (object == null) {
    return false;
  }

  const { name, label, description, enabled } = object;

  return isString(name) && isString(label) && isString(description) && isBoolean(enabled);
};

export const extractSastConfigurationEntities = ({ project }) => {
  if (!project?.sastCiConfiguration) {
    return [];
  }

  const { global, pipeline } = project.sastCiConfiguration;
  return [...global.nodes, ...pipeline.nodes];
};
