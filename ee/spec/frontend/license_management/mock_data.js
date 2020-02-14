import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

export const approvedLicense = {
  id: 5,
  name: 'MIT',
  approvalStatus: LICENSE_APPROVAL_STATUS.APPROVED,
};

export const blacklistedLicense = {
  id: 6,
  name: 'New BSD',
  approvalStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED,
};

export const licenseReport = [
  {
    name: 'New BSD',
    count: 5,
    url: 'http://opensource.org/licenses/BSD-3-Clause',
    packages: [
      {
        name: 'pg',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        paths: ['.'],
      },
      {
        name: 'puma',
        url: 'http://puma.io',
        description:
          'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        paths: ['.'],
      },
      {
        name: 'foo',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        paths: ['.'],
      },
      {
        name: 'bar',
        url: 'http://puma.io',
        description:
          'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        paths: ['.'],
      },
      {
        name: 'baz',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        paths: ['.'],
      },
    ],
  },
];

export default () => {};
