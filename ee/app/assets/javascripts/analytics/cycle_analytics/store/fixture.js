// TODO: replace this test data with an endpoint
import { __ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { getDateInPast } from '~/lib/utils/datetime_utility';
import { toYmd } from '../../shared/utils';

const today = new Date();
const dataRange = [...Array(30).keys()]
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

const genSeries = () => arrayToObject(dataRange.map(key => [key, randomInt(100)]));

const fakeApiResponse = convertObjectPropsToCamelCase(
  [
    {
      label: {
        id: 1,
        title: __('Bug'),
        color: '#428BCA',
        text_color: '#FFFFFF',
      },
      series: [genSeries()],
    },
    {
      label: {
        id: 3,
        title: __('Backstage'),
        color: '#327BCA',
        text_color: '#FFFFFF',
      },
      series: [genSeries()],
    },
    {
      label: {
        id: 2,
        title: __('Feature'),
        color: '#428BCA',
        text_color: '#FFFFFF',
      },
      series: [genSeries()],
    },
  ],
  { deep: true },
);

const transformResponseToLabelHash = data => {};

export const typeOfWork = convertObjectPropsToCamelCase(fakeApiResponse, { deep: true });
