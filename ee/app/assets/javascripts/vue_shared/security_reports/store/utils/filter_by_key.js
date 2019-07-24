/**
 * Compares two arrays by the given key and returns the difference
 *
 * @param {Array} firstArray
 * @param {Array} secondArray
 * @param {String} key
 * @returns {Array}
 */
const filterByKey = (firstArray = [], secondArray = [], key = '') =>
  firstArray.filter(item => !secondArray.find(el => el[key] === item[key]));

export default filterByKey;
