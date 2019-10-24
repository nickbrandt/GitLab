import httpStatus from '~/lib/utils/http_status';

export const currentStage = ({ stages, selectedStageName }) =>
  stages.length && selectedStageName
    ? stages.find(stage => stage.name === selectedStageName)
    : null;
export const defaultStage = state => (state.stages.length ? state.stages[0] : null);

export const hasNoAccessError = state => state.errorCode === httpStatus.FORBIDDEN;

export const currentGroupPath = ({ selectedGroup }) =>
  selectedGroup && selectedGroup.fullPath ? selectedGroup.fullPath : null;
