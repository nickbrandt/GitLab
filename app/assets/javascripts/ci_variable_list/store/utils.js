import { __ } from '~/locale';

const variableTypeHandler = type => (type === 'Variable' ? 'env_var' : 'file');

export const prepareDataForDisplay = variables => {
  const variablesToDisplay = [];
  variables.forEach(variable => {
    const variableCopy = variable;
    if (variableCopy.variable_type === 'env_var') {
      variableCopy.variable_type = __('Variable');
    } else {
      variableCopy.variable_type = __('File');
    }

    if (variableCopy.environment_scope === '*') {
      variableCopy.environment_scope = __('All environments');
    }
    variablesToDisplay.push(variableCopy);
  });
  return variablesToDisplay;
};

export const prepareDataForApi = (variable, destroy = false) => {
  const variableCopy = variable;
  variableCopy.protected.toString();
  variableCopy.masked.toString();
  variableCopy.variable_type = variableTypeHandler(variableCopy.variable_type);

  if (variableCopy.environment_scope === __('All environments')) {
    variableCopy.environment_scope = __('*');
  }

  if (destroy) {
    // eslint-disable-next-line
    variableCopy._destroy = destroy;
  }

  return variableCopy;
};

export const prepareEnvironments = environments => {
  const environmentNames = [];
  environments.forEach(environment => {
    environmentNames.push(environment.name);
  });
  return environmentNames;
};
