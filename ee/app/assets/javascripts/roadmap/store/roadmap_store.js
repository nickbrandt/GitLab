import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { newDate, parsePikadayDate } from '~/lib/utils/datetime_utility';

import { extendTimeframeForPreset, sortEpics } from '../utils/roadmap_utils';
import { PRESET_TYPES, EXTEND_AS } from '../constants';

export default class RoadmapStore {
  constructor({ groupId, timeframe, presetType, sortedBy }) {
    this.state = {};
    this.state.epics = [];
    this.state.epicIds = [];
    this.state.currentGroupId = groupId;
    this.state.timeframe = timeframe;

    this.presetType = presetType;
    this.sortedBy = sortedBy;
    this.initTimeframeThreshold();
  }

  initTimeframeThreshold() {
    const [startFrame] = this.state.timeframe;

    const lastTimeframeIndex = this.state.timeframe.length - 1;
    if (this.presetType === PRESET_TYPES.QUARTERS) {
      [this.timeframeStartDate] = startFrame.range;
      // eslint-disable-next-line prefer-destructuring
      this.timeframeEndDate = this.state.timeframe[lastTimeframeIndex].range[2];
    } else if (this.presetType === PRESET_TYPES.MONTHS) {
      this.timeframeStartDate = startFrame;
      this.timeframeEndDate = this.state.timeframe[lastTimeframeIndex];
    } else if (this.presetType === PRESET_TYPES.WEEKS) {
      this.timeframeStartDate = startFrame;
      this.timeframeEndDate = newDate(this.state.timeframe[lastTimeframeIndex]);
      this.timeframeEndDate.setDate(this.timeframeEndDate.getDate() + 7);
    }
  }

  setEpics(epics) {
    this.state.epicIds = [];
    this.state.epics = RoadmapStore.filterInvalidEpics({
      timeframeStartDate: this.timeframeStartDate,
      timeframeEndDate: this.timeframeEndDate,
      state: this.state,
      epics,
    });
  }

  addEpics(epics) {
    this.state.epics = this.state.epics.concat(
      RoadmapStore.filterInvalidEpics({
        timeframeStartDate: this.timeframeStartDate,
        timeframeEndDate: this.timeframeEndDate,
        state: this.state,
        newEpic: true,
        epics,
      }),
    );

    sortEpics(this.state.epics, this.sortedBy);
  }

  getEpics() {
    return this.state.epics;
  }

  getCurrentGroupId() {
    return this.state.currentGroupId;
  }

  getTimeframe() {
    return this.state.timeframe;
  }

  extendTimeframe(extendAs = EXTEND_AS.PREPEND) {
    const timeframeToExtend = extendTimeframeForPreset({
      presetType: this.presetType,
      extendAs,
      initialDate: extendAs === EXTEND_AS.PREPEND ? this.timeframeStartDate : this.timeframeEndDate,
    });

    if (extendAs === EXTEND_AS.PREPEND) {
      this.state.timeframe.unshift(...timeframeToExtend);
    } else {
      this.state.timeframe.push(...timeframeToExtend);
    }

    this.initTimeframeThreshold();

    this.state.epics.forEach(epic =>
      RoadmapStore.processEpicDates(epic, this.timeframeStartDate, this.timeframeEndDate),
    );

    return timeframeToExtend;
  }

  static filterInvalidEpics({
    epics,
    timeframeStartDate,
    timeframeEndDate,
    state,
    newEpic = false,
  }) {
    return epics.reduce((filteredEpics, epic) => {
      const formattedEpic = RoadmapStore.formatEpicDetails(
        epic,
        timeframeStartDate,
        timeframeEndDate,
      );
      // Exclude any Epic that has invalid dates
      // or is already present in Roadmap timeline
      if (
        formattedEpic.startDate <= formattedEpic.endDate &&
        state.epicIds.indexOf(formattedEpic.id) < 0
      ) {
        Object.assign(formattedEpic, {
          newEpic,
        });
        filteredEpics.push(formattedEpic);
        state.epicIds.push(formattedEpic.id);
      }
      return filteredEpics;
    }, []);
  }

  /**
   * This method constructs Epic object and assigns proxy dates
   * in case start or end dates are unavailable.
   *
   * @param {Object} rawEpic
   * @param {Date} timeframeStartDate
   * @param {Date} timeframeEndDate
   */
  static formatEpicDetails(rawEpic, timeframeStartDate, timeframeEndDate) {
    const epicItem = convertObjectPropsToCamelCase(rawEpic);

    if (rawEpic.start_date) {
      // If startDate is present
      const startDate = parsePikadayDate(rawEpic.start_date);
      epicItem.startDate = startDate;
      epicItem.originalStartDate = startDate;
    } else {
      // startDate is not available
      epicItem.startDateUndefined = true;
    }

    if (rawEpic.end_date) {
      // If endDate is present
      const endDate = parsePikadayDate(rawEpic.end_date);
      epicItem.endDate = endDate;
      epicItem.originalEndDate = endDate;
    } else {
      // endDate is not available
      epicItem.endDateUndefined = true;
    }

    RoadmapStore.processEpicDates(epicItem, timeframeStartDate, timeframeEndDate);

    return epicItem;
  }

  static processEpicDates(epic, timeframeStartDate, timeframeEndDate) {
    if (!epic.startDateUndefined) {
      // If startDate is less than first timeframe item
      if (epic.originalStartDate.getTime() < timeframeStartDate.getTime()) {
        Object.assign(epic, {
          // startDate is out of range
          startDateOutOfRange: true,
          // Use startDate object to set a proxy date so
          // that timeline bar can render it.
          startDate: newDate(timeframeStartDate),
        });
      } else {
        Object.assign(epic, {
          // startDate is within range
          startDateOutOfRange: false,
          // Set startDate to original startDate
          startDate: newDate(epic.originalStartDate),
        });
      }
    } else {
      Object.assign(epic, {
        startDate: newDate(timeframeStartDate),
      });
    }

    if (!epic.endDateUndefined) {
      // If endDate is greater than last timeframe item
      if (epic.originalEndDate.getTime() > timeframeEndDate.getTime()) {
        Object.assign(epic, {
          // endDate is out of range
          endDateOutOfRange: true,
          // Use endDate object to set a proxy date so
          // that timeline bar can render it.
          endDate: newDate(timeframeEndDate),
        });
      } else {
        Object.assign(epic, {
          // startDate is within range
          endDateOutOfRange: false,
          // Set startDate to original startDate
          endDate: newDate(epic.originalEndDate),
        });
      }
    } else {
      Object.assign(epic, {
        endDate: newDate(timeframeEndDate),
      });
    }
  }
}
