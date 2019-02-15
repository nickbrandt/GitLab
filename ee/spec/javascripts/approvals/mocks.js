export const createProjectRules = () => [
  { id: 1, name: 'Lorem', approvalsRequired: 2, approvers: [{ id: 7 }, { id: 8 }] },
  { id: 2, name: 'Ipsum', approvalsRequired: 0, approvers: [{ id: 9 }] },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, approvers: [] },
];

export const createMRRule = () => ({
  id: 7,
  name: 'Amit',
  approvers: [{ id: 1 }, { id: 2 }],
  approvalsRequired: 2,
  minApprovalsRequired: 0,
});

export const createMRRuleWithSource = () => ({
  ...createMRRule(),
  minApprovalsRequired: 1,
  hasSource: true,
  sourceId: 3,
});
