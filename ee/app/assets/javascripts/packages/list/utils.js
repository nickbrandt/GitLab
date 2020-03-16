import { LIST_KEY_PROJECT, TABLE_HEADER_FIELDS } from './constants';

export default isGroupPage =>
  TABLE_HEADER_FIELDS.filter(f => f.key !== LIST_KEY_PROJECT || isGroupPage);
