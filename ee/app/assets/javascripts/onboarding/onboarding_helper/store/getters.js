export const stepIndex = state => {
  const { tourData, tourKey, url, projectFullPath, createdProjectPath } = state;
  let idx = -1;

  if (tourData && tourData[tourKey] && url !== '') {
    idx = tourData[tourKey].findIndex(item =>
      item.forUrl({ projectFullPath, createdProjectPath }).test(state.url),
    );
  }

  return idx !== -1 ? idx : null;
};

export const stepContent = (state, getters) => {
  const { tourData, tourKey } = state;

  if (!tourData || !tourData[tourKey] || getters.stepIndex === null) {
    return null;
  }

  return tourData[tourKey][getters.stepIndex] ? tourData[tourKey][getters.stepIndex] : null;
};

export const helpContent = (state, getters) => {
  const { projectName, helpContentIndex } = state;

  if (getters.stepContent === null) {
    return null;
  }

  return getters.stepContent.getHelpContent
    ? getters.stepContent.getHelpContent({ projectName })[helpContentIndex]
    : null;
};

export const totalTourPartSteps = state => {
  if (state.tourData && state.tourKey && state.tourData[state.tourKey]) {
    return state.tourData[state.tourKey].length;
  }

  return 0;
};

export const percentageCompleted = state => {
  const { tourData, tourKey, lastStepIndex } = state;

  if (lastStepIndex === -1 || !tourData || !tourData[tourKey]) {
    return 0;
  }

  return Math.floor((100 * lastStepIndex) / tourData[tourKey].length);
};

export const actionPopover = (state, getters) =>
  getters.stepContent !== null && getters.stepContent.actionPopover
    ? getters.stepContent.actionPopover
    : null;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
