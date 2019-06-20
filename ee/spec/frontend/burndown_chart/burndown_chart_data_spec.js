import dateFormat from 'dateformat';
import BurndownChartData from 'ee/burndown_chart/burndown_chart_data';

describe('BurndownChartData', () => {
  const startDate = '2017-03-01';
  const dueDate = '2017-03-03';

  const milestoneEvents = [
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
    { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
    { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'reopened' },
  ];

  let burndownChartData;

  beforeEach(() => {
    burndownChartData = new BurndownChartData(milestoneEvents, startDate, dueDate);
  });

  describe('generate', () => {
    it('generates an array of arrays with date, issue count and weight', () => {
      expect(burndownChartData.generate()).toEqual([
        ['2017-03-01', 2, 4],
        ['2017-03-02', 1, 2],
        ['2017-03-03', 3, 6],
      ]);
    });

    describe('when issues are created before start date', () => {
      beforeAll(() => {
        milestoneEvents.push({
          created_at: '2017-02-28T00:00:00.000Z',
          weight: 2,
          action: 'created',
        });
      });

      it('generates an array of arrays with date, issue count and weight', () => {
        expect(burndownChartData.generate()).toEqual([
          ['2017-03-01', 3, 6],
          ['2017-03-02', 2, 4],
          ['2017-03-03', 4, 8],
        ]);
      });
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
