const INVITATIONS_API_INVALID_EMAIL_ADDRESS = {
  message: { error: 'email contains an invalid email address' },
};

const INVITATIONS_API_INVALID_EMAIL_SINGLE = {
  error: 'email contains an invalid email address',
};

const INVITATIONS_API_RESTRICTED_EMAIL_ERROR = {
  message: {
    'email@example.com':
      "Invite email 'email@example.com' does not match the allowed domains: example1.org",
  },
  status: 'error',
};

const INVITATIONS_API_MULTIPLE_RESTRICTED = {
  message: {
    'email@example.com':
      "Invite email email 'email@example.com' does not match the allowed domains: example1.org",
    'email4@example.com':
      "Invite email email 'email4@example.com' does not match the allowed domains: example1.org",
  },
  status: 'error',
};

const INVITATIONS_API_EMAIL_TAKEN = {
  message: {
    'email@example2.com': 'Invite email has already been taken',
  },
  status: 'error',
};

const MEMBERS_API_MEMBER_ALREADY_EXISTS = {
  message: 'Member already exists',
};

const MEMBERS_API_SINGLE_USER_RESTRICTED = {
  message: { user: ["email 'email@example.com' does not match the allowed domains: example1.org"] },
};

const MEMBERS_API_SINGLE_USER_ACCESS_LEVEL = {
  message: {
    access_level: [
      'should be greater than or equal to Owner inherited membership from group Gitlab Org',
    ],
  },
};

const MEMBERS_API_MULTIPLE_USERS_RESTRICTED = {
  message:
    "root: User email 'admin@example.com' does not match the allowed domain of example2.com and user18: User email 'user18@example.org' does not match the allowed domain of example2.com",
  status: 'error',
};

export const apiPaths = {
  GROUPS_MEMBERS: '/api/v4/groups/1/members',
  GROUPS_INVITATIONS: '/api/v4/groups/1/invitations',
};

export const membersApiResponse = {
  MEMBER_ALREADY_EXISTS: MEMBERS_API_MEMBER_ALREADY_EXISTS,
  SINGLE_USER_ACCESS_LEVEL: MEMBERS_API_SINGLE_USER_ACCESS_LEVEL,
  SINGLE_USER_RESTRICTED: MEMBERS_API_SINGLE_USER_RESTRICTED,
  MULTIPLE_USERS_RESTRICTED: MEMBERS_API_MULTIPLE_USERS_RESTRICTED,
};

export const invitationsApiResponse = {
  INVALID_EMAIL_ADDRESS: INVITATIONS_API_INVALID_EMAIL_ADDRESS,
  INVALID_EMAIL_SINGLE: INVITATIONS_API_INVALID_EMAIL_SINGLE,
  RESTRICTED_EMAIL_ERROR: INVITATIONS_API_RESTRICTED_EMAIL_ERROR,
  MULTIPLE_RESTRICTED: INVITATIONS_API_MULTIPLE_RESTRICTED,
  EMAIL_TAKEN: INVITATIONS_API_EMAIL_TAKEN,
};
