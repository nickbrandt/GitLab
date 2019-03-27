import createState from 'ee/insights/stores/modules/insights/state';
import mutations from 'ee/insights/stores/modules/insights/mutations';
import * as types from 'ee/insights/stores/modules/insights/mutation_types';

describe('Insights mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.REQUEST_CONFIG, () => {
    it('sets configLoading state when starting request', () => {
      mutations[types.REQUEST_CONFIG](state);

      expect(state.configLoading).toBe(true);
    });

    it('resets configData state when starting request', () => {
      mutations[types.REQUEST_CONFIG](state);

      expect(state.configData).toBe(null);
    });
  });

  describe(types.RECEIVE_CONFIG_SUCCESS, () => {
    const data = [
      {
        key: 'chart',
      },
    ];

    it('sets configLoading state to false on success', () => {
      mutations[types.RECEIVE_CONFIG_SUCCESS](state, data);

      expect(state.configLoading).toBe(false);
    });

    it('sets configData state to incoming data on success', () => {
      mutations[types.RECEIVE_CONFIG_SUCCESS](state, data);

      expect(state.configData).toBe(data);
    });
  });

  describe(types.RECEIVE_CONFIG_ERROR, () => {
    it('sets configLoading state to false on error', () => {
      mutations[types.RECEIVE_CONFIG_ERROR](state);

      expect(state.configLoading).toBe(false);
    });

    it('sets configData state to null on error', () => {
      mutations[types.RECEIVE_CONFIG_ERROR](state);

      expect(state.configData).toBe(null);
    });
  });

  describe(types.REQUEST_CHART, () => {
    it('sets chartLoading state when starting request', () => {
      mutations[types.REQUEST_CHART](state);

      expect(state.chartLoading).toBe(true);
    });

    it('resets chartData state when starting request', () => {
      mutations[types.REQUEST_CHART](state);

      expect(state.chartData).toBe(null);
    });
  });

  describe(types.RECEIVE_CHART_SUCCESS, () => {
    const data = {
      labels: ['January'],
      datasets: [
        {
          label: 'Dataset 1',
          fill: true,
          backgroundColor: ['rgba(255, 99, 132)'],
          data: [1],
        },
        {
          label: 'Dataset 2',
          fill: true,
          backgroundColor: ['rgba(54, 162, 235)'],
          data: [2],
        },
      ],
    };

    it('sets chartLoading state to false on success', () => {
      mutations[types.RECEIVE_CHART_SUCCESS](state, data);

      expect(state.chartLoading).toBe(false);
    });

    it('sets chartData state to incoming data on success', () => {
      mutations[types.RECEIVE_CHART_SUCCESS](state, data);

      expect(state.chartData).toBe(data);
    });
  });

  describe(types.RECEIVE_CHART_ERROR, () => {
    it('sets chartLoading state to false on error', () => {
      mutations[types.RECEIVE_CHART_ERROR](state);

      expect(state.chartLoading).toBe(false);
    });

    it('sets chartData state to null on error', () => {
      mutations[types.RECEIVE_CHART_ERROR](state);

      expect(state.chartData).toBe(null);
    });
  });

  describe(types.SET_ACTIVE_TAB, () => {
    it('sets activeTab state', () => {
      mutations[types.SET_ACTIVE_TAB](state, 'key');

      expect(state.activeTab).toBe('key');
    });
  });

  describe(types.SET_ACTIVE_CHART, () => {
    let chartData;

    beforeEach(() => {
      chartData = { key: 'chart' };
    });

    it('sets activeChart state', () => {
      mutations[types.SET_ACTIVE_CHART](state, chartData);

      expect(state.activeChart).toBe(chartData);
    });
  });
});
