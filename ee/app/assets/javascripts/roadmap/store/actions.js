import flash from '~/flash';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

import * as epicUtils from '../utils/epic_utils';
import {
  getEpicsPathForPreset,
  getEpicsTimeframeRange,
  sortEpics,
  extendTimeframeForPreset,
} from '../utils/roadmap_utils';
import { EXTEND_AS } from '../constants';

import groupEpics from '../queries/groupEpics.query.graphql';
import epicChildEpics from '../queries/epicChildEpics.query.graphql';

import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const setWindowResizeInProgress = ({ commit }, inProgress) =>
  commit(types.SET_WINDOW_RESIZE_IN_PROGRESS, inProgress);

export const fetchGroupEpics = (
  { epicIid, fullPath, epicsState, sortedBy, presetType, filterParams, timeframe },
  defaultTimeframe,
) => {
  let query;
  let variables = {
    fullPath,
    state: epicsState,
    sort: sortedBy,
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
  };

  // When epicIid is present,
  // Roadmap is being accessed from within an Epic,
  // and then we don't need to pass `filterParams`.
  if (epicIid) {
    query = epicChildEpics;
    variables.iid = epicIid;
  } else {
    query = groupEpics;
    variables = {
      ...variables,
      ...filterParams,
    };
  }

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const { group } = data;
      let edges;

      if (epicIid) {
        edges = (group.epic && group.epic.children.edges) || [];
      } else {
        edges = (group.epics && group.epics.edges) || [];
      }

      return epicUtils.extractGroupEpics(edges);
    });
};

export const requestEpics = ({ commit }) => commit(types.REQUEST_EPICS);
export const requestEpicsForTimeframe = ({ commit }) => commit(types.REQUEST_EPICS_FOR_TIMEFRAME);
export const receiveEpicsSuccess = (
  { commit, state, getters },
  { rawEpics, newEpic, timeframeExtended },
) => {
  const epics = rawEpics.reduce((filteredEpics, epic) => {
    const formattedEpic = epicUtils.formatEpicDetails(
      epic,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    );
    // Exclude any Epic that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedEpic.startDate.getTime() <= formattedEpic.endDate.getTime() &&
      state.epicIds.indexOf(formattedEpic.id) < 0
    ) {
      Object.assign(formattedEpic, {
        newEpic,
      });
      filteredEpics.push(formattedEpic);
      commit(types.UPDATE_EPIC_IDS, formattedEpic.id);
    }
    return filteredEpics;
  }, []);

  if (timeframeExtended) {
    const updatedEpics = state.epics.concat(epics);
    sortEpics(updatedEpics, state.sortedBy);
    commit(types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS, updatedEpics);
  } else {
    commit(types.RECEIVE_EPICS_SUCCESS, epics);
  }
};
export const receiveEpicsFailure = ({ commit }) => {
  commit(types.RECEIVE_EPICS_FAILURE);
  flash(s__('GroupRoadmap|Something went wrong while fetching epics'));
};
export const fetchEpics = ({ state, dispatch }) => {
  dispatch('requestEpics');

  return axios
    .get(state.initialEpicsPath)
    .then(({ data }) => {
      dispatch('receiveEpicsSuccess', { rawEpics: data });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const fetchEpicsGQL = ({ state, dispatch }) => {
  dispatch('requestEpics');

  fetchGroupEpics(state)
    .then(rawEpics => {
      dispatch('receiveEpicsSuccess', { rawEpics });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const fetchEpicsForTimeframe = ({ state, dispatch }, { timeframe }) => {
  dispatch('requestEpicsForTimeframe');

  const epicsPath = getEpicsPathForPreset({
    basePath: state.basePath,
    epicsState: state.epicsState,
    filterQueryString: state.filterQueryString,
    presetType: state.presetType,
    timeframe,
  });

  return axios
    .get(epicsPath)
    .then(({ data }) => {
      dispatch('receiveEpicsSuccess', {
        rawEpics: data,
        newEpic: true,
        timeframeExtended: true,
      });
    })
    .catch(() => {
      dispatch('receiveEpicsFailure');
    });
};

export const fetchEpicsForTimeframeGQL = ({ state, dispatch }, { timeframe }) => {
  dispatch('requestEpicsForTimeframe');

  return fetchGroupEpics(state, timeframe)
    .then(rawEpics => {
      dispatch('receiveEpicsSuccess', {
        rawEpics,
        newEpic: true,
        timeframeExtended: true,
      });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const extendTimeframe = ({ commit, state, getters }, { extendAs }) => {
  const isExtendTypePrepend = extendAs === EXTEND_AS.PREPEND;

  const timeframeToExtend = extendTimeframeForPreset({
    extendAs,
    presetType: state.presetType,
    initialDate: isExtendTypePrepend ? getters.timeframeStartDate : getters.timeframeEndDate,
  });

  if (isExtendTypePrepend) {
    commit(types.PREPEND_TIMEFRAME, timeframeToExtend);
  } else {
    commit(types.APPEND_TIMEFRAME, timeframeToExtend);
  }
};

export const refreshEpicDates = ({ commit, state, getters }) => {
  const epics = state.epics.map(epic =>
    epicUtils.processEpicDates(epic, getters.timeframeStartDate, getters.timeframeEndDate),
  );

  commit(types.SET_EPICS, epics);
};

export const setBufferSize = ({ commit }, bufferSize) => commit(types.SET_BUFFER_SIZE, bufferSize);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
