// TODO: replace this test data with an endpoint
import { __ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { getDateInPast } from '~/lib/utils/datetime_utility';
import { toYmd } from '../../shared/utils';

const today = new Date();
const generateRange = (limit = 30) =>
  [...Array(limit).keys()]
    .map(i => {
      const d = getDateInPast(today, i);
      return toYmd(new Date(d));
    })
    .reverse();

function randomInt(range) {
  return Math.floor(Math.random() * Math.floor(range));
}

function arrayToObject(arr) {
  return arr.reduce((acc, curr) => {
    const [key, value] = curr;
    return { ...acc, [key]: value };
  }, {});
}

const genSeries = dayRange =>
  arrayToObject(generateRange(dayRange).map(key => [key, randomInt(100)]));

const generateApiResponse = dayRange =>
  convertObjectPropsToCamelCase(
    [
      {
        label: {
          id: 1,
          title: __('Bug'),
          color: '#428BCA',
          text_color: '#FFFFFF',
        },
        series: [genSeries(dayRange)],
      },
      {
        label: {
          id: 3,
          title: __('Backstage'),
          color: '#327BCA',
          text_color: '#FFFFFF',
        },
        series: [genSeries(dayRange)],
      },
      {
        label: {
          id: 2,
          title: __('Feature'),
          color: '#428BCA',
          text_color: '#FFFFFF',
        },
        series: [genSeries(dayRange)],
      },
    ],
    { deep: true },
  );

const transformResponseToLabelHash = data =>
  data.reduce(
    (acc, { label: { id, ...labelRest }, series }) => ({
      ...acc,
      [id]: {
        label: { id, ...labelRest },
        series,
      },
    }),
    {},
  );

export const typeOfWork = dayRange =>
  transformResponseToLabelHash(
    convertObjectPropsToCamelCase(generateApiResponse(dayRange), { deep: true }),
  );

export default {};
