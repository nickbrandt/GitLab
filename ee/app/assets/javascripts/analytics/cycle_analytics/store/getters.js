export const currentStage = ({ stages, selectedStageName }) =>
  stages.length && selectedStageName
    ? stages.find(stage => stage.name === selectedStageName)
    : null;
export const defaultStage = state => (state.stages.length ? state.stages[0] : null);
