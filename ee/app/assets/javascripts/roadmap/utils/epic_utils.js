import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { newDate, parsePikadayDate } from '~/lib/utils/datetime_utility';

/**
 * Updates provided `epic` object with necessary props
 * representing underlying dates.
 *
 * @param {Object} epic
 * @param {Date} timeframeStartDate
 * @param {Date} timeframeEndDate
 */
export const processEpicDates = (epic, timeframeStartDate, timeframeEndDate) => {
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

  return epic;
};

/**
 * Constructs Epic object with camelCase props and assigns proxy dates in case
 * start or end dates are unavailable.
 *
 * @param {Object} rawEpic
 * @param {Date} timeframeStartDate
 * @param {Date} timeframeEndDate
 */
export const formatEpicDetails = (rawEpic, timeframeStartDate, timeframeEndDate) => {
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

  processEpicDates(epicItem, timeframeStartDate, timeframeEndDate);

  return epicItem;
};
