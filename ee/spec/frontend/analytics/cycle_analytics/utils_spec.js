import {
  isStartEvent,
  isLabelEvent,
  getAllowedEndEvents,
  eventToOption,
  eventsByIdentifier,
  getLabelEventsIdentifiers,
  nestQueryStringKeys,
  flattenDurationChartData,
  getDurationChartData,
  transformRawStages,
  isPersistedStage,
  getTasksByTypeData,
  flattenTaskByTypeSeries,
} from 'ee/analytics/cycle_analytics/utils';
import {
  customStageEvents as events,
  labelStartEvent,
  labelStopEvent,
  customStageStartEvents as startEvents,
  transformedDurationData,
  flattenedDurationData,
  durationChartPlottableData,
  startDate,
  endDate,
  issueStage,
  rawCustomStage,
  tasksByTypeData,
} from './mock_data';

const labelEvents = [labelStartEvent, labelStopEvent].map(i => i.identifier);

describe('Cycle analytics utils', () => {
  describe('isStartEvent', () => {
    it('will return true for a valid start event', () => {
      expect(isStartEvent(startEvents[0])).toEqual(true);
    });

    it('will return false for input that is not a start event', () => {
      [{ identifier: 'fake-event', canBeStartEvent: false }, {}, [], null, undefined].forEach(
        ev => {
          expect(isStartEvent(ev)).toEqual(false);
        },
      );
    });
  });

  describe('isLabelEvent', () => {
    it('will return true if the given event identifier is in the labelEvents array', () => {
      expect(isLabelEvent(labelEvents, labelStartEvent.identifier)).toEqual(true);
    });
    it('will return false if the given event identifier is not in the labelEvents array', () => {
      [startEvents[1].identifier, null, undefined, ''].forEach(ev => {
        expect(isLabelEvent(labelEvents, ev)).toEqual(false);
      });
      expect(isLabelEvent(labelEvents)).toEqual(false);
    });
  });

  describe('eventToOption', () => {
    it('will return null if no valid object is passed in', () => {
      [{}, [], null, undefined].forEach(i => {
        expect(eventToOption(i)).toEqual(null);
      });
    });

    it('will set the "value" property to the events identifier', () => {
      events.forEach(ev => {
        const res = eventToOption(ev);
        expect(res.value).toEqual(ev.identifier);
      });
    });

    it('will set the "text" property to the events name', () => {
      events.forEach(ev => {
        const res = eventToOption(ev);
        expect(res.text).toEqual(ev.name);
      });
    });
  });

  describe('getLabelEventsIdentifiers', () => {
    it('will return an array of identifiers for the label events', () => {
      const res = getLabelEventsIdentifiers(events);
      expect(res.length).toEqual(labelEvents.length);
      expect(res).toEqual(labelEvents);
    });

    it('will return an empty array when there are no matches', () => {
      const ev = [{ _type: 'simple' }, { type: 'simple' }, { t: 'simple' }];
      expect(getLabelEventsIdentifiers(ev)).toEqual([]);
      expect(getLabelEventsIdentifiers([])).toEqual([]);
    });
  });

  describe('getAllowedEndEvents', () => {
    it('will return the relevant end events for a given start event identifier', () => {
      const se = events[0];
      expect(getAllowedEndEvents(events, se.identifier)).toEqual(se.allowedEndEvents);
    });

    it('will return an empty array if there are no end events available', () => {
      ['cool_issue_label_added', [], {}, null, undefined].forEach(ev => {
        expect(getAllowedEndEvents(events, ev)).toEqual([]);
      });
    });
  });

  describe('eventsByIdentifier', () => {
    it('will return the events with an identifier in the provided array', () => {
      expect(eventsByIdentifier(events, labelEvents)).toEqual([labelStartEvent, labelStopEvent]);
    });

    it('will return an empty array if there are no matching events', () => {
      [['lol', 'bad'], [], {}, null, undefined].forEach(items => {
        expect(eventsByIdentifier(events, items)).toEqual([]);
      });
      expect(eventsByIdentifier([], labelEvents)).toEqual([]);
    });
  });

  describe('nestQueryStringKeys', () => {
    const targetKey = 'foo';
    const obj = { bar: 10, baz: 'awesome', qux: false, boo: ['lol', 'something'] };

    it('will return an object with each key nested under the targetKey', () => {
      expect(nestQueryStringKeys(obj, targetKey)).toEqual({
        'foo[bar]': 10,
        'foo[baz]': 'awesome',
        'foo[qux]': false,
        'foo[boo]': ['lol', 'something'],
      });
    });

    it('returns an empty object if the targetKey is not a valid string', () => {
      ['', null, {}, []].forEach(badStr => {
        expect(nestQueryStringKeys(obj, badStr)).toEqual({});
      });
    });

    it('will return an empty object if given an empty object', () => {
      [{}, null, [], ''].forEach(tarObj => {
        expect(nestQueryStringKeys(tarObj, targetKey)).toEqual({});
      });
    });
  });

  describe('flattenDurationChartData', () => {
    it('flattens the data as expected', () => {
      const flattenedData = flattenDurationChartData(transformedDurationData);

      expect(flattenedData).toStrictEqual(flattenedDurationData);
    });
  });

  describe('cycleAnalyticsDurationChart', () => {
    it('computes the plottable data as expected', () => {
      const plottableData = getDurationChartData(transformedDurationData, startDate, endDate);

      expect(plottableData).toStrictEqual(durationChartPlottableData);
    });
  });

  describe('transformRawStages', () => {
    it('retains all the stage properties', () => {
      const transformed = transformRawStages([issueStage, rawCustomStage]);
      expect(transformed).toMatchSnapshot();
    });

    it('converts object properties from snake_case to camelCase', () => {
      const [transformedCustomStage] = transformRawStages([rawCustomStage]);
      expect(transformedCustomStage).toMatchObject({
        endEventIdentifier: 'issue_first_added_to_board',
        startEventIdentifier: 'issue_first_mentioned_in_commit',
      });
    });

    it('sets the slug to the value of the stage id', () => {
      const transformed = transformRawStages([issueStage, rawCustomStage]);
      transformed.forEach(t => {
        expect(t.slug).toEqual(t.id);
      });
    });

    it('sets the name to the value of the stage title if its not set', () => {
      const transformed = transformRawStages([issueStage, rawCustomStage]);
      transformed.forEach(t => {
        expect(t.name.length > 0).toBe(true);
        expect(t.name).toEqual(t.title);
      });
    });
  });

  describe('isPersistedStage', () => {
    it.each`
      custom   | id                    | expected
      ${true}  | ${'this-is-a-string'} | ${true}
      ${true}  | ${42}                 | ${true}
      ${false} | ${42}                 | ${true}
      ${false} | ${'this-is-a-string'} | ${false}
    `('with custom=$custom and id=$id', ({ custom, id, expected }) => {
      expect(isPersistedStage({ custom, id })).toEqual(expected);
    });
  });

  describe.skip('flattenTaskByTypeSeries', () => {});

  describe.only('getTasksByTypeData', () => {
    let transformed = {};
    const rawData = tasksByTypeData;
    const labels = rawData.map(d => {
      const { label } = d;
      return label.title;
    });

    const data = rawData.map(d => {
      const { series } = d;
      return flattenTaskByTypeSeries(series);
    });

    const range = [];
    console.log('rawData', rawData);
    // console.log('labels', labels);
    console.log('data', data);

    beforeEach(() => {
      transformed = getTasksByTypeData({ data: rawData, startDate, endDate });
    });

    it('will return an object with the properties needed for the chart', () => {
      ['seriesNames', 'data', 'range'].forEach(key => {
        expect(transformed).toHaveProperty(key);
      });
    });

    describe('seriesNames', () => {
      it('returns the names of all the labels in the dataset', () => {
        expect(transformed.seriesNames).toEqual(labels);
      });
    });

    describe('range', () => {
      it('returns the date range as an array', () => {
        expect(transformed.range).toEqual(range);
      });
      it('includes each day between the start date and end date', () => {
        expect(transformed.range).toEqual(range);
      });
      it('includes the start date and end date', () => {
        expect(transformed.range).toContain(startDate);
        expect(transformed.range).toContain(endDate);
      });
    });

    describe('data', () => {
      it('returns an array of data points', () => {
        expect(transformed.data).toEqual(data);
      });

      it('contains an array of data for each label', () => {
        expect(transformed.data.length).toEqual(labels.length);
      });

      it('contains a value for each day in the range', () => {
        transformed.data.forEach(d => {
          expect(d.length).toEqual(transformed.range.length);
        });
      });
    });
  });
});
