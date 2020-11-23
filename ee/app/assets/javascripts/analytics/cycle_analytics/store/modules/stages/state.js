export default () => ({
  isLoadingStage: false,
  isEmptyStage: false,
  isSavingStageOrder: false, // TODO: can we remove?
  errorSavingStageOrder: false,

  selectedStage: null,
  currentStageEvents: [],
  medians: {},
});
