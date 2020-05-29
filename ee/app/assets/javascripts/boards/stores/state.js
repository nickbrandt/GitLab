import createStateCE from '~/boards/stores/state';

export default () => ({
  ...createStateCE(),

  isShowingEpicsSwimlanes: false,
});
