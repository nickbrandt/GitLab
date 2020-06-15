import { parsePikadayDate, pikadayToString } from '~/lib/utils/datetime_utility';

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

export const createAuditEventSearchQuery = ({ filterValue, startDate, endDate, sortBy }) => ({
  entity_id: filterValue.id,
  entity_type: filterValue.type,
  created_after: startDate ? pikadayToString(startDate) : null,
  created_before: endDate ? pikadayToString(endDate) : null,
  sort: sortBy,
});
