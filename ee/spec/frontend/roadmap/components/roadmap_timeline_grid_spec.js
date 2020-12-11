import { shallowMount } from '@vue/test-utils';
import PImage from 'pureimage';
import { setTestTimeout } from 'helpers/timeout';

import RoadmapTimelineGrid from 'ee/roadmap/components/roadmap_timeline_grid.vue';
import {
  PRESET_TYPES,
  TIMELINE_CELL_MIN_WIDTH,
  EPIC_DETAILS_CELL_WIDTH,
  DAYS_IN_WEEK,
  EPIC_ITEM_HEIGHT,
} from 'ee/roadmap/constants';

import { mockMonthly, mockWeekly, mockQuarterly } from 'ee_jest/roadmap/mock_data';
import { presetTypeTestCases } from 'ee_jest/roadmap/roadmap_item_test_cases';

/* eslint-disable import/no-commonjs */
const { Writable } = require('stream');

const mockMonthlyViewWidth =
  mockMonthly.timeframe.length * TIMELINE_CELL_MIN_WIDTH + EPIC_DETAILS_CELL_WIDTH;

setTestTimeout(1000);

describe('RoadmapTimelineGrid component', () => {
  let wrapper;
  let canvas;
  let ctx;

  const getCanvas = () => wrapper.vm.$refs.canvas;

  class BufferStream extends Writable {
    constructor() {
      super();
      this.chunks = [];
    }

    _write(chunk, _, cb) {
      this.chunks.push(chunk);
      return cb();
    }

    getBuffer() {
      return Buffer.concat(this.chunks);
    }
  }

  const setupGetContextMock = () => {
    jest.spyOn(window.HTMLCanvasElement.prototype, 'getContext').mockImplementation(() => {
      return {
        beginPath: () => {},
        strokeStyle: undefined,
        lineWidth: undefined,
        moveTo: () => {},
        lineTo: () => {},
        stroke: () => {},
      };
    });
  };

  const setupCanvasStub = (width, height) => {
    canvas = PImage.make(width, height);
    ctx = canvas.getContext('2d');

    jest.spyOn(window.HTMLCanvasElement.prototype, 'getContext').mockImplementation(() => {
      return ctx;
    });
  };

  const createWrapper = ({
    presetType = PRESET_TYPES.MONTHS,
    timeframe = mockMonthly.timeframe,
    height = EPIC_ITEM_HEIGHT,
    currentDate = mockMonthly.currentDate,
    stubDrawMethod = true,
  } = {}) => {
    const options = {
      propsData: {
        presetType,
        timeframe,
        height,
      },
      data() {
        return {
          currentDate,
        };
      },
    };

    if (stubDrawMethod) {
      options.methods = {
        draw: () => {},
      };
    }

    wrapper = shallowMount(RoadmapTimelineGrid, options);
  };

  beforeEach(() => {
    setupGetContextMock();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    jest.clearAllMocks();
  });

  describe('computed', () => {
    describe.each(presetTypeTestCases)('%s', (computedPropName, presetType, timeframe) => {
      beforeEach(() => {
        createWrapper({ presetType, timeframe });
      });

      it(`returns true when presetType is PRESET_TYPE.${presetType}`, () => {
        expect(wrapper.vm[computedPropName]).toBe(true);
      });
    });

    const computedTestCases = [
      [
        `current date is set to ${mockWeekly.currentDate.toDateString()} under weekly timeframe`,
        {
          propsData: {
            presetType: PRESET_TYPES.WEEKS,
            timeframe: mockWeekly.timeframe,
          },
          data: {
            currentDate: mockWeekly.currentDate,
          },
          expected: {
            timeframeItemIndex: mockWeekly.currentIndex,
            timeframeItem: mockWeekly.timeframe[mockWeekly.currentIndex],
            // timeframe.currentDate = Oct 11th. It is 0th day in the week.
            // It should be placed at the beginning of the cell representing the week.
            // Take a look at roadmap_timeline_grid.vue for a detailed explanation
            innerOffset: TIMELINE_CELL_MIN_WIDTH / DAYS_IN_WEEK / 2,
            offset: mockWeekly.currentIndex * TIMELINE_CELL_MIN_WIDTH,
            rowWidth:
              mockWeekly.timeframe.length * TIMELINE_CELL_MIN_WIDTH + EPIC_DETAILS_CELL_WIDTH,
          },
        },
      ],
      [
        `current date is set to ${mockMonthly.currentDate.toDateString()} under monthly timeframe`,
        {
          propsData: {}, // Use default props passed to "createWrapper".
          data: {
            currentDate: mockMonthly.currentDate,
          },
          expected: {
            timeframeItemIndex: mockMonthly.currentIndex,
            timeframeItem: mockMonthly.timeframe[mockMonthly.currentIndex],
            // timeframe.currentDate = Dec 1 and there are 31 days in Dec.
            // The location of the current date should be
            //  '1 / 31 * TIMELINE_CELL_MIN_WIDTH' away
            //  from the beginning of the cell representing the timeframeItem.
            innerOffset: (1 / 31) * TIMELINE_CELL_MIN_WIDTH,
            offset: mockMonthly.currentIndex * TIMELINE_CELL_MIN_WIDTH,
            rowWidth:
              mockMonthly.timeframe.length * TIMELINE_CELL_MIN_WIDTH + EPIC_DETAILS_CELL_WIDTH,
          },
        },
      ],
      [
        `current date is set to ${mockQuarterly.currentDate.toDateString()} under quarterly timeframe`,
        {
          propsData: {
            presetType: PRESET_TYPES.QUARTERS,
            timeframe: mockQuarterly.timeframe,
          },
          data: {
            currentDate: mockQuarterly.currentDate,
          },
          expected: {
            timeframeItemIndex: mockQuarterly.currentIndex,
            timeframeItem: mockQuarterly.timeframe[mockQuarterly.currentIndex],
            // timeframe.currentDate = Dec 25 which is 86th day in this quarter.
            // Total number of days in Q4 = 31(oct) + 30(nov) + 31(dec) = 92 days.
            // The location of the current date should be
            //  '86 / 92 * TIMELINE_CELL_MIN_WIDTH' away
            //  from the beginning of the cell representing the timeframeItem.
            innerOffset: (86 / 92) * TIMELINE_CELL_MIN_WIDTH,
            offset: mockQuarterly.currentIndex * TIMELINE_CELL_MIN_WIDTH,
            rowWidth:
              mockQuarterly.timeframe.length * TIMELINE_CELL_MIN_WIDTH + EPIC_DETAILS_CELL_WIDTH,
          },
        },
      ],
    ];

    describe.each(computedTestCases)(`when %s`, (_, { propsData, data, expected }) => {
      beforeEach(() => {
        createWrapper({ ...propsData, ...data });
      });

      describe('timeframeItemForToday', () => {
        it('returns correct index for the element in timeframe array', () => {
          expect(wrapper.vm.timeframeItemIndexForToday).toBe(expected.timeframeItemIndex);
        });
      });

      describe('timeframeItemIndexForToday', () => {
        it('returns correct item containing the current date in "timeframe" array', () => {
          expect(wrapper.vm.timeframeItemForToday).toEqual(expected.timeframeItem);
        });
      });

      describe('innerOffset', () => {
        it('returns correct offset (in px) for the current date indicator within its timeframe', () => {
          expect(wrapper.vm.innerOffset).toBe(expected.innerOffset);
        });
      });

      describe('offset', () => {
        it('returns correct distance (in px) from the first available timeframe to the current timeframe.', () => {
          expect(wrapper.vm.offset).toBe(expected.offset);
        });
      });

      describe('rowWidth', () => {
        it('returns correct width for canvas element representing a row', () => {
          expect(wrapper.vm.rowWidth).toBe(expected.rowWidth);
        });
      });
    });

    describe('canvasContext', () => {
      let mockContext;

      beforeEach(() => {
        mockContext = {};

        jest.spyOn(window.HTMLCanvasElement.prototype, 'getContext').mockImplementation(() => {
          return mockContext;
        });

        createWrapper();
      });

      it('returns the context for canvas element', () => {
        expect(wrapper.vm.canvasContext).toEqual(mockContext);
      });
    });
  });

  describe('methods', () => {
    describe('hasToday', () => {
      describe.each`
        timeframe      | presetType               | mockData
        ${'weekly'}    | ${PRESET_TYPES.WEEKS}    | ${mockWeekly}
        ${'monthly'}   | ${PRESET_TYPES.MONTHS}   | ${mockMonthly}
        ${'quarterly'} | ${PRESET_TYPES.QUARTERS} | ${mockQuarterly}
      `(`under $timeframe view`, ({ mockData, presetType }) => {
        beforeEach(() => {
          createWrapper({
            presetType,
            timeframe: mockData.timeframe,
            currentDate: mockData.currentDate,
          });
        });

        describe(`when given a timeframeItem that has the current date`, () => {
          it('returns true', () => {
            const timeframeItem = mockData.timeframe[mockData.currentIndex];

            expect(wrapper.vm.hasToday(timeframeItem)).toBe(true);
          });
        });

        describe(`when given a timeframeItem that doesn't have the current date`, () => {
          it('returns false', () => {
            const timeframeItem = mockData.timeframe[mockData.currentIndex + 1];

            expect(wrapper.vm.hasToday(timeframeItem)).toBe(false);
          });
        });
      });
    });
  });

  describe('template', () => {
    describe('canvas', () => {
      const expectCanvasToMatchsnapshot = async customSnapshotIdentifier => {
        const bufferStream = new BufferStream();

        bufferStream.on('finish', () => {
          const rawPngBuffer = bufferStream.getBuffer();
          expect(rawPngBuffer).toMatchImageSnapshot({
            customSnapshotIdentifier,
          });
        });

        await PImage.encodePNGToStream(canvas, bufferStream);
      };

      it('renders with correct width and height', () => {
        createWrapper();

        expect(getCanvas().height).toBe(EPIC_ITEM_HEIGHT);
        expect(getCanvas().width).toBe(mockMonthlyViewWidth);
      });

      it(`correctly renders grid with current date indicator w: ${mockMonthlyViewWidth} * h: ${EPIC_ITEM_HEIGHT}`, async () => {
        createWrapper({ stubDrawMethod: false });

        const { width, height } = getCanvas();
        setupCanvasStub(width, height);

        wrapper.vm.draw();

        await wrapper.vm.$nextTick();

        await expectCanvasToMatchsnapshot('correctly_rendered_timeline_grid1');
      });

      describe('when `timeframe` is updated', () => {
        const earlierMonth = mockMonthly.timeframe[0].getMonth() - 1;
        const extendedTimeframe = [new Date(2020, earlierMonth, 1), ...mockMonthly.timeframe];
        const extendedWidth = mockMonthlyViewWidth + TIMELINE_CELL_MIN_WIDTH;

        it('renders with correct width', async () => {
          createWrapper();

          wrapper.setProps({ timeframe: extendedTimeframe });

          await wrapper.vm.$nextTick();

          expect(getCanvas().width).toBe(extendedWidth);
        });

        it(`correctly re-renders grid with current date indicator w: ${extendedWidth} * h: ${EPIC_ITEM_HEIGHT}`, async () => {
          createWrapper({ stubDrawMethod: false });

          setupCanvasStub(extendedWidth, EPIC_ITEM_HEIGHT);

          wrapper.setProps({ timeframe: extendedTimeframe });

          await wrapper.vm.$nextTick();

          await expectCanvasToMatchsnapshot('correctly_rendered_timeline_grid2');
        });
      });

      describe('when height is updated', () => {
        const extendedHeight = 60;

        it('renders with correct height', async () => {
          createWrapper();

          wrapper.setProps({ height: extendedHeight });

          await wrapper.vm.$nextTick();

          expect(getCanvas().height).toBe(extendedHeight);
        });

        it(`correctly re-renders grid with current date indicator w: ${mockMonthlyViewWidth} * h: ${extendedHeight}`, async () => {
          createWrapper({ stubDrawMethod: false });

          setupCanvasStub(mockMonthlyViewWidth, extendedHeight);

          wrapper.setProps({ height: extendedHeight });

          await wrapper.vm.$nextTick();

          await expectCanvasToMatchsnapshot('correctly_rendered_timeline_grid3');
        });
      });
    });
  });
});
