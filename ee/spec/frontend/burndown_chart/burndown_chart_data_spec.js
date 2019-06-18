import dateFormat from 'dateformat';
import BurndownChartData from 'ee/burndown_chart/burndown_chart_data';

describe('BurndownChartData', () => {
  const milestoneEvents = [
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.190Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-01T00:00:00.478Z', weight: 2, action: 'reopened' },
    { created_at: '2017-03-01T00:00:00.597Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-01T00:00:00.767Z', weight: 2, action: 'reopened' },
    { created_at: '2017-03-03T00:00:00.260Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-03T00:00:00.152Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-03T00:00:00.572Z', weight: 2, action: 'reopened' },
    { created_at: '2017-03-03T00:00:00.450Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-03T00:00:00.352Z', weight: 2, action: 'reopened' },
  ];
  const startDate = '2017-03-01';
  const dueDate = '2017-03-03';

  let burndownChartData;

  beforeEach(() => {
    burndownChartData = new BurndownChartData(milestoneEvents, startDate, dueDate);
  });

  describe('generate', () => {
    it('generates an array of arrays with date, issue count and weight', () => {
      expect(burndownChartData.generate()).toEqual([
        ['2017-03-01', 5, 10],
        ['2017-03-02', 5, 10],
        ['2017-03-03', 4, 8],
      ]);
    });

    describe('when viewing before due date', () => {
      beforeAll(() => {
        const today = new Date(2017, 2, 2);

        // eslint-disable-next-line no-global-assign
        Date = class extends Date {
          constructor(date) {
            super(date || today);
          }
        };
      });

      it('counts until today if milestone due date > date today', () => {
        const chartData = burndownChartData.generate();
        expect(dateFormat(new Date(), 'yyyy-mm-dd')).toEqual('2017-03-02');
        expect(chartData[chartData.length - 1][0]).toEqual('2017-03-02');
      });
    });
  });
});
