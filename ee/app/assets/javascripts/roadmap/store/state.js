export default () => ({
  // API Calls
  basePath: '',
  epicsState: '',
  filterQueryString: '',
  initialEpicsPath: '',

  // Data
  epics: [],
  epicIds: [],
  currentGroupId: -1,
  timeframe: [],
  extendedTimeframe: [],
  presetType: '',
  sortedBy: '',

  // UI Flags
  epicsFetchInProgress: false,
  epicsFetchForTimeframeInProgress: false,
  epicsFetchFailure: false,
  epicsFetchResultEmpty: false,
});
