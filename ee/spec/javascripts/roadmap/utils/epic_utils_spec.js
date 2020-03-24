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

describe('addIsChildEpicTrueProperty', () => {
  it('adds `isChildEpic` property with value `true`', () => {
    const obj = {
      title: 'Lorem ipsum dolar sit',
    };

    const newObj = epicUtils.addIsChildEpicTrueProperty(obj);

    expect(newObj.isChildEpic).toBe(true);
  });
});

describe('generateKey', () => {
  it('returns epic namespaced key for an epic object', () => {
    const obj = {
      id: 3,
      title: 'Lorem ipsum dolar sit',
      isChildEpic: false,
    };

    expect(epicUtils.generateKey(obj)).toBe('epic-3');
  });

  it('returns child-epic- namespaced key for a child epic object', () => {
    const obj = {
      id: 3,
      title: 'Lorem ipsum dolar sit',
      isChildEpic: true,
    };

    expect(epicUtils.generateKey(obj)).toBe('child-epic-3');
  });
});
