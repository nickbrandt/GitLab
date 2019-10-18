import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

const urlFor = ({ scheme = 'https', host = 'www.example.org', path = '/' }) =>
  `${scheme}://${host}${path}`;
const licenseUrlFor = name =>
  urlFor({ host: 'opensource.org', path: `/licenses/${name.split(' ')[0]}` });
const dependencyUrlFor = name => urlFor({ path: `/${name}` });
const normalizeV1License = ({ name, url = licenseUrlFor(name) }) => ({ name, url });
const V1 = {
  normalizeLicenseSummary: ({ name, url = licenseUrlFor(name), count = 0 }) => ({
    name,
    url,
    count,
  }),
  normalizeDependency: ({
    name,
    url = dependencyUrlFor(name),
    description = name.toUpperCase(),
    license = {},
  }) => ({ dependency: { name, url, description }, license: normalizeV1License(license) }),
};
const V2 = {
  normalizeLicenseSummary: ({ id, name, url = licenseUrlFor(id) }) => ({ id, name, url }),
  normalizeDependency: ({
    name,
    url = dependencyUrlFor(name),
    description = name.toUpperCase(),
    licenses = [],
  }) => ({ name, url, licenses, description }),
};

export class Builder {
  static for(version, template = { licenses: [], dependencies: [] }) {
    return new Builder(version, template);
  }

  static forV1() {
    return this.for(V1);
  }

  static forV2() {
    return this.for(V2, { version: '2.0', licenses: [], dependencies: [] });
  }

  constructor(version, template = { licenses: [], dependencies: [] }) {
    this.report = template;
    this.version = version;
  }

  addLicense(license) {
    this.report.licenses.push(this.version.normalizeLicenseSummary(license));
    return this;
  }

  addDependency(dependency) {
    this.report.dependencies.push(this.version.normalizeDependency(dependency));
    return this;
  }

  build(override = {}) {
    return Object.assign(this.report, override);
  }
}

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

export const licenseBaseIssues = Builder.forV1()
  .addLicense({ name: 'MIT', count: 1 })
  .addDependency({
    name: 'bundler',
    url: 'http://bundler.io',
    description: "The best way to manage your application's dependencies",
    license: { name: 'MIT', url: 'http://opensource.org/licenses/mit-license' },
  })
  .build();

export const licenseHeadIssues = Builder.forV1()
  .addLicense({ name: 'New BSD', count: 3 })
  .addLicense({ name: 'MIT', count: 1 })
  .addDependency({
    name: 'pg',
    url: 'https://bitbucket.org/ged/ruby-pg',
    description: 'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
    license: { name: 'New BSD', url: 'http://opensource.org/licenses/BSD-3-Clause' },
  })
  .addDependency({
    name: 'puma',
    url: 'http://puma.io',
    description:
      'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
    license: { name: 'New BSD', url: 'http://opensource.org/licenses/BSD-3-Clause' },
  })
  .addDependency({
    name: 'foo',
    url: 'http://foo.io',
    description:
      'Foo is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
    license: { name: 'New BSD', url: 'http://opensource.org/licenses/BSD-3-Clause' },
  })
  .addDependency({
    name: 'execjs',
    url: 'https://github.com/rails/execjs',
    description: 'Run JavaScript code from Ruby',
    license: { name: 'MIT', url: 'http://opensource.org/licenses/mit-license' },
  })
  .build();

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
