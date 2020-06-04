import createStateCE from '~/boards/stores/state';

export default () => ({
  ...createStateCE(),

  isShowingEpicsSwimlanes: false,
  epicsSwimlanesFetchInProgress: false,
  epicsSwimlanesFetchFailure: false,
  epicsSwimlanes: {},
});
