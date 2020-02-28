export const MOCK_SELECTIVE_SYNC_TYPES = {
  ALL: {
    label: 'All projects',
    value: '',
  },
  NAMESPACES: {
    label: 'Projects in certain groups',
    value: 'namespaces',
  },
  SHARDS: {
    label: 'Projects in certain storage shards',
    value: 'shards',
  },
};

export const MOCK_SYNC_SHARDS = [
  {
    label: 'Shard 1',
    value: 'shard1',
  },
  {
    label: 'Shard 2',
    value: 'shard2',
  },
  {
    label: 'Shard 3',
    value: 'shard3',
  },
];

export const MOCK_SYNC_NAMESPACES = [
  {
    name: 'Namespace 1',
    id: 'namespace1',
  },
  {
    name: 'Namespace 2',
    id: 'namespace2',
  },
  {
    name: 'namespace 3',
    id: 'Namespace3',
  },
];

export const MOCK_NODE = {
  id: 1,
  name: 'Mock Node',
  url: 'https://mock_node.gitlab.com',
  primary: false,
  internalUrl: '',
  selectiveSyncType: '',
  selectiveSyncNamespaceIds: [],
  selectiveSyncShards: [],
  reposMaxCapacity: 25,
  filesMaxCapacity: 10,
  verificationMaxCapacity: 100,
  containerRepositoriesMaxCapacity: 10,
  minimumReverificationInterval: 7,
  syncObjectStorage: false,
};
