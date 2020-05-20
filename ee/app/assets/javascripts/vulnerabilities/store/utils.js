/**
 * Returns the index of an issue in given list
 * @param {String} date the date in '01 Jan 1970 00:00:00 GMT' format
 * @return {Number} the date converted to number of seconds since January 1, 1970, 00:00:00 UTC
 */
export const dateToSeconds = date => {
  return Date.parse(date) / 1000;
};

export default {};
