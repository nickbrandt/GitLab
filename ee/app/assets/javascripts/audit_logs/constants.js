import { __, s__ } from '~/locale';
import UserToken from './components/tokens/user_token.vue';
import ProjectToken from './components/tokens/project_token.vue';
import GroupToken from './components/tokens/group_token.vue';

const DEFAULT_TOKEN_OPTIONS = {
  operators: [{ value: '=', description: __('is'), default: 'true' }],
  unique: true,
};

export const FILTER_TOKENS = [
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'user',
    title: s__('AuditLogs|User Events'),
    type: 'User',
    token: UserToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'bookmark',
    title: s__('AuditLogs|Project Events'),
    type: 'Project',
    token: ProjectToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'group',
    title: s__('AuditLogs|Group Events'),
    type: 'Group',
    token: GroupToken,
  },
];

export const AVAILABLE_TOKEN_TYPES = FILTER_TOKENS.map(token => token.type);
