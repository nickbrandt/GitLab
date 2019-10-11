import dateFormat from 'dateformat';
import timezoneMock from 'timezone-mock';
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

    describe('when viewing in a timezone in the west', () => {
      beforeAll(() => {
        timezoneMock.register('US/Pacific');
      });

      afterAll(() => {
        timezoneMock.unregister();
      });

      it('has the right start and end dates', () => {
        expect(burndownChartData.generate()).toEqual([
          ['2017-03-01', 1, 2],
          ['2017-03-02', 3, 6],
          ['2017-03-03', 3, 6],
        ]);
      });
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
      const realDateNow = Date.now;

      beforeAll(() => {
        const today = jest.fn(() => new Date(2017, 2, 2));
        global.Date.now = today;
      });

      afterAll(() => {
        global.Date.now = realDateNow;
      });

      it('counts until today if milestone due date > date today', () => {
        const chartData = burndownChartData.generate();

        expect(dateFormat(Date.now(), 'yyyy-mm-dd')).toEqual('2017-03-02');
        expect(chartData[chartData.length - 1][0]).toEqual('2017-03-02');
      });
    });

    describe('when days in milestone have negative counts', () => {
      describe('and the first two days have a negative count', () => {
        beforeAll(() => {
          milestoneEvents.length = 0;
          milestoneEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
          );
        });

        it('generates an array where the first two days counts are zero', () => {
          expect(burndownChartData.generate()).toEqual([
            ['2017-03-01', 0, 0],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 1, 2],
          ]);
        });
      });

      describe('and the middle day has a negative count', () => {
        // This scenario is unlikely to occur as this implies there are more
        // closed issues than total issues, but we account for it anyway as a
        // potential edge case.

        beforeAll(() => {
          milestoneEvents.length = 0;
          milestoneEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
          );
        });

        it('generates an array where the middle day count is zero', () => {
          expect(burndownChartData.generate()).toEqual([
            ['2017-03-01', 1, 2],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 1, 2],
          ]);
        });
      });

      describe('and the last day has a negative count', () => {
        // This scenario is unlikely to occur as this implies there are more
        // closed issues than total issues, but we account for it anyway as a
        // potential edge case.

        beforeAll(() => {
          milestoneEvents.length = 0;
          milestoneEvents.push(
            { created_at: '2017-03-01T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-02T00:00:00.000Z', weight: 2, action: 'closed' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'created' },
            { created_at: '2017-03-03T00:00:00.000Z', weight: 2, action: 'closed' },
          );
        });

        it('generates an array where all counts are zero', () => {
          expect(burndownChartData.generate()).toEqual([
            ['2017-03-01', 0, 0],
            ['2017-03-02', 0, 0],
            ['2017-03-03', 0, 0],
          ]);
        });
      });
    });
  });
});
