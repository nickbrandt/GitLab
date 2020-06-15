import { parseAuditEventSearchQuery, createAuditEventSearchQuery } from 'ee/audit_events/utils';

describe('Audit Event Utils', () => {
  describe('parseAuditEventSearchQuery', () => {
    it('returns a query object with parsed date values', () => {
      const input = {
        created_after: '2020-03-13',
        created_before: '2020-04-13',
        sortBy: 'created_asc',
      };
      expect(parseAuditEventSearchQuery(input)).toEqual({
        created_after: new Date('2020-03-13'),
        created_before: new Date('2020-04-13'),
        sortBy: 'created_asc',
      });
    });
  });

  describe('createAuditEventSearchQuery', () => {
    it('returns a query object with remapped keys and stringified dates', () => {
      const input = {
        filterValue: {
          id: '1',
          type: 'user',
        },
        startDate: new Date('2020-03-13'),
        endDate: new Date('2020-04-13'),
        sortBy: 'bar',
      };
      expect(createAuditEventSearchQuery(input)).toEqual({
        entity_id: '1',
        entity_type: 'user',
        created_after: '2020-03-13',
        created_before: '2020-04-13',
        sort: 'bar',
      });
    });
  });
});
