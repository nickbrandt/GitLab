import * as epicUtils from 'ee/roadmap/utils/epic_utils';

import { mockGroupEpicsQueryResponse } from '../mock_data';

describe('extractGroupEpics', () => {
  it('returns array of epics with `edges->nodes` nesting removed', () => {
    const { edges } = mockGroupEpicsQueryResponse.data.group.epics;
    const extractedEpics = epicUtils.extractGroupEpics(edges);

    expect(extractedEpics.length).toBe(edges.length);
    expect(extractedEpics[0]).toEqual(
      jasmine.objectContaining({
        ...edges[0].node,
        groupName: edges[0].node.group.name,
        groupFullName: edges[0].node.group.fullName,
      }),
    );
  });
});
