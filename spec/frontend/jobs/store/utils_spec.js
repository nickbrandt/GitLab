import {
  logLinesParser,
  updateIncrementalTrace,
  parseLine,
  parseHeaderLine,
  addDurationToHeader,
  findOffsetAndRemove,
} from '~/jobs/store/utils';
import {
  utilsMockData,
  originalTrace,
  regularIncremental,
  regularIncrementalRepeated,
  headerTrace,
  headerTraceIncremental,
  collapsibleTrace,
  collapsibleTraceIncremental,
} from '../components/log/mock_data';

describe('Jobs Store Utils', () => {
  describe('parseLine', () => {
    it('returns a new object with the lineNumber key added to the provided line object', () => {
      const line = { content: [{ text: 'foo' }] };
      const parsed = parseLine(line, 1);
      expect(parsed.content).toEqual(line.content);
      expect(parsed.lineNumber).toEqual(1);
    });
  });

  describe('parseHeaderLine', () => {
    it('returns a new object with the header keys and the provided line parsed', () => {
      const headerLine = { content: [{ text: 'foo' }] };
      const parsedHeaderLine = parseHeaderLine(headerLine, 2);

      expect(parsedHeaderLine).toEqual({
        isClosed: true,
        isHeader: true,
        line: {
          ...headerLine,
          lineNumber: 2,
        },
        lines: [],
      });
    });
  });

  describe('addDurationToHeader', () => {
    it('adds the section duration to the matching section', () => {
      const parsed = [
        {
          isClosed: true,
          isHeader: true,
          line: {
            section: 'prepare-script',
            content: [{ text: 'foo' }],
          },
          lines: [],
        },
      ];
      const duration = {
        offset: 106,
        content: [],
        section: 'prepare-script',
        section_duration: '00:03',
      };

      addDurationToHeader(parsed, duration);

      expect(parsed[0].line.section_duration).toEqual(duration.section_duration);
    });

    describe('without matching section', () => {
      it('does not add the provided duration', () => {
        const parsed = [
          {
            isClosed: true,
            isHeader: true,
            line: {
              section: 'prepare-executor',
              content: [{ text: 'foo' }],
            },
            lines: [],
          },
        ];
        const duration = {
          offset: 106,
          content: [],
          section: 'prepare-script',
          section_duration: '00:03',
        };

        addDurationToHeader(parsed, duration);
        expect(parsed.section_duration).toEqual(undefined);
      });
    });
  });

  describe('logLinesParser', () => {
    let result;

    beforeEach(() => {
      result = logLinesParser(utilsMockData);
    });

    describe('regular line', () => {
      it('adds a lineNumber property with correct index', () => {
        expect(result[0].lineNumber).toEqual(0);
        expect(result[1].line.lineNumber).toEqual(1);
      });
    });

    describe('collpasible section', () => {
      it('adds a `isClosed` property', () => {
        expect(result[1].isClosed).toEqual(true);
      });

      it('adds a `isHeader` property', () => {
        expect(result[1].isHeader).toEqual(true);
      });

      it('creates a lines array property with the content of the collpasible section', () => {
        expect(result[1].lines.length).toEqual(2);
        expect(result[1].lines[0].content).toEqual(utilsMockData[2].content);
        expect(result[1].lines[1].content).toEqual(utilsMockData[3].content);
      });
    });

    describe('section duration', () => {
      it('adds the section information to the header section', () => {
        expect(result[1].line.section_duration).toEqual(utilsMockData[4].section_duration);
      });

      it('does not add section duration as a line', () => {
        expect(result[1].lines.includes(utilsMockData[4])).toEqual(false);
      });
    });
  });

  describe('updateIncrementalTrace', () => {
    describe('without repeated section', () => {
      it('adds new line', () => {
        const oldLog = logLinesParser(originalTrace);

        const result = updateIncrementalTrace(regularIncremental, oldLog);

        expect(result).toEqual([
          {
            offset: 1,
            content: [
              {
                text: 'Downloading',
              },
            ],
            lineNumber: 0,
          },
          {
            offset: 2,
            content: [
              {
                text: 'log line',
              },
            ],
            lineNumber: 1,
          },
        ]);
      });
    });

    describe('with regular line repeated offset', () => {
      it('updates the last line and formats with the incremental part', () => {
        const oldLog = logLinesParser(originalTrace);
        const result = updateIncrementalTrace(regularIncrementalRepeated, oldLog);

        expect(result).toEqual([
          {
            offset: 1,
            content: [
              {
                text: 'log line',
              },
            ],
            lineNumber: 0,
          },
        ]);
      });
    });

    describe('with header line repeated', () => {
      it('updates the header line and formats with the incremental part', () => {
        const oldLog = logLinesParser(headerTrace);
        const result = updateIncrementalTrace(headerTraceIncremental, oldLog);

        expect(result).toEqual([
          {
            isClosed: true,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'updated log line',
                },
              ],
              section: 'section',
              lineNumber: 0,
            },
            lines: [],
          },
        ]);
      });
    });

    describe('with collapsible line repeated', () => {
      it('updates the collapsible line and formats with the incremental part', () => {
        const oldLog = logLinesParser(collapsibleTrace);
        const result = updateIncrementalTrace(collapsibleTraceIncremental, oldLog);

        expect(result).toEqual([
          {
            isClosed: true,
            isHeader: true,
            line: {
              offset: 1,
              section_header: true,
              content: [
                {
                  text: 'log line',
                },
              ],
              section: 'section',
              lineNumber: 0,
            },
            lines: [
              {
                offset: 2,
                content: [
                  {
                    text: 'updated log line',
                  },
                ],
                section: 'section',
                lineNumber: 1,
              },
            ],
          },
        ]);
      });
    });
  });

  describe('findOffsetAndRemove', () => {
    describe('when last item matches the offset', () => {
      it('returns an object with the item removed and the lastLine', () => {
        const newData = [{ offset: 10, content: [{ text: 'foobar' }] }];
        const existingLog = [{ line: { content: [{ text: 'bar' }], offset: 10, lineNumber: 1 } }];
        const result = findOffsetAndRemove(newData, existingLog);
        expect(result).toEqual([]);
      });
    });

    describe('when last nested line item matches the offset', () => {
      it('returns an object with the last nested line item removed and the lastLine', () => {
        const newData = [{ offset: 101, content: [{ text: 'foobar' }] }];
        const existingLog = [
          {
            lines: [{ offset: 101, content: [{ text: 'foobar' }], lineNumber: 2 }],
            line: {
              offset: 10,
              lineNumber: 1,
            },
          },
        ];
        const result = findOffsetAndRemove(newData, existingLog);
        expect(result).toEqual([{ offset: 10, lines: [], lineNumber: 1 }]);
      });
    });

    describe('when it does not match the offset', () => {
      it('returns an object with the complete old log and the last line number', () => {
        const newData = [{ offset: 101, content: [{ text: 'foobar' }] }];
        const existingLog = [{ line: { content: [{ text: 'bar' }], offset: 10, lineNumber: 1 } }];
        const result = findOffsetAndRemove(newData, existingLog);
        expect(result).toEqual(existingLog);
      });
    });
  });
});
