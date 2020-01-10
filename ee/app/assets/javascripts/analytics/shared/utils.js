import dateFormat from 'dateformat';
import { dateFormats } from './constants';

export const toYmd = date => dateFormat(date, dateFormats.isoDate);

export default {
  toYmd,
};

export const formattedDate = d => dateFormat(d, dateFormats.defaultDate);
