import dateFormat from 'dateformat';
import Api from 'ee/api';
import { getDayDifference, getDateInPast } from '~/lib/utils/datetime_utility';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';
import { dateFormats } from '../../../../shared/constants';

export const requestDurationData = ({ commit }) => commit(types.REQUEST_DURATION_DATA);

export const receiveDurationDataSuccess = ({ commit, rootState, dispatch }, data) => {
  commit(types.RECEIVE_DURATION_DATA_SUCCESS, data);

  const { featureFlags: { hasDurationChartMedian = false } = {} } = rootState;
  if (hasDurationChartMedian) dispatch('fetchDurationMedianData');
};

export const receiveDurationDataError = ({ commit }) => {
  commit(types.RECEIVE_DURATION_DATA_ERROR);
  createFlash(__('There was an error while fetching value stream analytics duration data.'));
};

export const fetchDurationData = ({ dispatch, rootGetters, rootState }) => {
  dispatch('requestDurationData');

  const {
    stages,
    selectedGroup: { fullPath },
  } = rootState;

  const {
    cycleAnalyticsRequestParams: { created_after, created_before, project_ids },
  } = rootGetters;

  return Promise.all(
    stages.map(stage => {
      const { slug } = stage;

      return Api.cycleAnalyticsDurationChart(fullPath, slug, {
        created_after,
        created_before,
        project_ids,
      }).then(({ data }) => ({
        slug,
        selected: true,
        data,
      }));
    }),
  )
    .then(data => dispatch('receiveDurationDataSuccess', data))
    .catch(() => dispatch('receiveDurationDataError'));
};

export const receiveDurationMedianDataSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_DURATION_MEDIAN_DATA_SUCCESS, data);

export const receiveDurationMedianDataError = ({ commit }) => {
  commit(types.RECEIVE_DURATION_MEDIAN_DATA_ERROR);
  createFlash(__('There was an error while fetching value stream analytics duration median data.'));
};

export const fetchDurationMedianData = ({ dispatch, rootState, rootGetters }) => {
  const {
    stages,
    selectedGroup: { fullPath },
    startDate,
    endDate,
  } = rootState;
  const {
    cycleAnalyticsRequestParams: { project_ids },
  } = rootGetters;

  const offsetValue = getDayDifference(new Date(startDate), new Date(endDate));
  const offsetCreatedAfter = getDateInPast(new Date(startDate), offsetValue);
  const offsetCreatedBefore = getDateInPast(new Date(endDate), offsetValue);

  return Promise.all(
    stages.map(stage => {
      const { slug } = stage;

      return Api.cycleAnalyticsDurationChart(fullPath, slug, {
        created_after: dateFormat(offsetCreatedAfter, dateFormats.isoDate),
        created_before: dateFormat(offsetCreatedBefore, dateFormats.isoDate),
        project_ids,
      }).then(({ data }) => ({
        slug,
        selected: true,
        data,
      }));
    }),
  )
    .then(data => dispatch('receiveDurationMedianDataSuccess', data))
    .catch(() => dispatch('receiveDurationMedianDataError'));
};

export const updateSelectedDurationChartStages = ({ state, commit }, stages) => {
  const setSelectedPropertyOnStages = data =>
    data.map(stage => {
      const selected = stages.reduce((result, object) => {
        if (object.slug === stage.slug) return true;
        return result;
      }, false);

      return {
        ...stage,
        selected,
      };
    });

  const { durationData, durationMedianData } = state;
  const updatedDurationStageData = setSelectedPropertyOnStages(durationData);
  const updatedDurationStageMedianData = setSelectedPropertyOnStages(durationMedianData);

  commit(types.UPDATE_SELECTED_DURATION_CHART_STAGES, {
    updatedDurationStageData,
    updatedDurationStageMedianData,
  });
};
