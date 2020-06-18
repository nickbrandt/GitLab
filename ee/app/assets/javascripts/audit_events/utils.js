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
  const entityValue = filterValue.find(value => AVAILABLE_TOKEN_TYPES.includes(value.type));

  return {
    created_after: startDate ? pikadayToString(startDate) : null,
    created_before: endDate ? pikadayToString(endDate) : null,
    sort: sortBy,
    entity_id: entityValue?.value.data,
    entity_type: entityValue?.type,
    // When changing the search parameters, we should be resetting to the first page
    page: null,
  };
};
