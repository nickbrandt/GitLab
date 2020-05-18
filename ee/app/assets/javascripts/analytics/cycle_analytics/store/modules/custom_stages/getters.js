// eslint-disable-next-line import/prefer-default-export
export const customStageFormActive = ({ isCreatingCustomStage, isEditingCustomStage }) =>
  Boolean(isCreatingCustomStage || isEditingCustomStage);
