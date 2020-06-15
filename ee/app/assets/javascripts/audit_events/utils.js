import { parsePikadayDate, pikadayToString } from '~/lib/utils/datetime_utility';
import { AVAILABLE_TOKEN_TYPES } from './constants';

export const isNumeric = str => {
  return !Number.isNaN(parseInt(str, 10), 10);
};

export const parseAuditEventSearchQuery = ({
  created_after: createdAfter,
  created_before: createdBefore,
  ...restOfParams
}) => ({
  ...restOfParams,
  created_after: createdAfter ? parsePikadayDate(createdAfter) : null,
  created_before: createdBefore ? parsePikadayDate(createdBefore) : null,
});

export const createAuditEventSearchQuery = ({ filterValue, startDate, endDate, sortBy }) => {
  const entityValues = filterValue.filter(value => AVAILABLE_TOKEN_TYPES.includes(value.type));
  let searchQuery = {
    created_after: startDate ? pikadayToString(startDate) : null,
    created_before: endDate ? pikadayToString(endDate) : null,
    sort: sortBy,
  };

  if (entityValues.length) {
    const {
      type,
      value: { data: id },
    } = entityValues[0] || { type: null, value: { data: null } };

    searchQuery = { ...searchQuery, entity_id: id, entity_type: type };
  }

  return searchQuery;
};
