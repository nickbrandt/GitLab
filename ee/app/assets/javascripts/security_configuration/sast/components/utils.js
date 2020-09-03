const isString = value => typeof value === 'string';
const isBoolean = value => typeof value === 'boolean';

const validateSastCiConfigurationEntity = object => {
  const { field, type, description, label, defaultValue, value } = object;

  return (
    isString(field) &&
    isString(type) &&
    isString(description) &&
    isString(label) &&
    defaultValue !== undefined &&
    value !== undefined
  );   
}

const validateSastCiConfigurationAnalyzersEntity = object => {
  const { name, label, description, enabled } = object;

  return (
    isString(name) &&
    isString(label) &&
    isString(description) &&
    isBoolean(enabled)
  );   
}

export const isValidConfigurationEntity = object => {
  if (object == null) {
    return false;
  }

  const entityType = object.__typename;

  if(entityType==="SastCiConfigurationEntity"){
    return validateSastCiConfigurationEntity(object)
  }

  if(entityType==="SastCiConfigurationAnalyzersEntity"){
    return validateSastCiConfigurationAnalyzersEntity(object)
  }    

}


export const extractSastConfigurationEntities = ({ project }) => {
  if (!project?.sastCiConfiguration) {
    return [];
  }

  const { global, pipeline, analyzers } = project.sastCiConfiguration;
  return [...global.nodes, ...pipeline.nodes, ...analyzers.nodes];
};
