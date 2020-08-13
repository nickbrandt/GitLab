const isString = value => typeof value === 'string';

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

export const extractSastConfigurationEntities = ({ project }) => {
  if (!project?.sastCiConfiguration) {
    return [];
  }

  const { global, pipeline } = project.sastCiConfiguration;
  return [...global.nodes, ...pipeline.nodes];
};
