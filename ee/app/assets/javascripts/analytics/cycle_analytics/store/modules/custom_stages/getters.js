// eslint-disable-next-line import/prefer-default-export
export const customStageFormActive = ({ isCreating, isEditing }) =>
  Boolean(isCreating || isEditing);
