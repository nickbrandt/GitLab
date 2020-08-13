import {
  appendToPreviousResult,
  removeProfile,
  dastSiteProfilesDeleteResponse,
} from 'ee/dast_profiles/graphql/cache_utils';

describe('EE - DastProfiles GraphQL CacheUtils', () => {
  describe('appendToPreviousResult', () => {
    it('appends new results to previous', () => {
      const previousResult = { project: { siteProfiles: { edges: ['foo'] } } };
      const fetchMoreResult = { project: { siteProfiles: { edges: ['bar'] } } };

      const expected = { project: { siteProfiles: { edges: ['foo', 'bar'] } } };
      const result = appendToPreviousResult(previousResult, { fetchMoreResult });

      expect(result).toEqual(expected);
    });
  });

  describe('removeProfile', () => {
    it('removes the profile with the given id from the cache', () => {
      const mockQueryBody = { query: 'foo', variables: { foo: 'bar' } };
      const mockProfiles = [{ id: 0 }, { id: 1 }];
      const mockData = {
        project: {
          siteProfiles: {
            edges: [{ node: mockProfiles[0] }, { node: mockProfiles[1] }],
          },
        },
      };
      const mockStore = {
        readQuery: () => mockData,
        writeQuery: jest.fn(),
      };

      removeProfile({
        store: mockStore,
        queryBody: mockQueryBody,
        profileToBeDeletedId: mockProfiles[0].id,
      });

      expect(mockStore.writeQuery).toHaveBeenCalledWith({
        ...mockQueryBody,
        data: {
          project: {
            siteProfiles: {
              edges: [{ node: mockProfiles[1] }],
            },
          },
        },
      });
    });
  });

  describe('dastSiteProfilesDeleteResponse', () => {
    it('returns a mutation response with the correct shape', () => {
      expect(dastSiteProfilesDeleteResponse()).toEqual({
        __typename: 'Mutation',
        dastSiteProfileDelete: {
          __typename: 'DastSiteProfileDeletePayload',
          errors: [],
        },
      });
    });
  });
});
