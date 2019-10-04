import ReportMapper from 'ee/vue_shared/license_management/report_mapper';

describe('mapFrom', () => {
  let subject = null;

  beforeEach(() => {
    subject = new ReportMapper(true);
  });

  it('converts a v2 schema report to v1', () => {
    const report = {
      version: '2.0',
      licenses: [
        { id: 'MIT', name: 'MIT License', url: 'https://opensource.org/licenses/MIT' },
        { id: 'BSD', name: 'BSD License', url: 'https://opensource.org/licenses/BSD' },
      ],
      dependencies: [
        { name: 'x', url: 'https://www.example.com/x', licenses: ['MIT'], description: 'X' },
        { name: 'y', url: 'https://www.example.com/y', licenses: ['BSD'], description: 'Y' },
        {
          name: 'z',
          url: 'https://www.example.com/z',
          licenses: ['BSD', 'MIT'],
          description: 'Z',
        },
      ],
    };
    const result = subject.mapFrom(report);

    expect(result).toMatchObject({
      licenses: [{ name: 'BSD License', count: 2 }, { name: 'MIT License', count: 2 }],
      dependencies: [
        {
          license: {
            name: 'MIT License',
            url: 'https://opensource.org/licenses/MIT',
          },
          dependency: {
            name: 'x',
            url: 'https://www.example.com/x',
            description: 'X',
          },
        },
        {
          license: {
            name: 'BSD License',
            url: 'https://opensource.org/licenses/BSD',
          },
          dependency: {
            name: 'y',
            url: 'https://www.example.com/y',
            description: 'Y',
          },
        },
        {
          license: {
            name: 'BSD License, MIT License',
            url: '',
          },
          dependency: {
            name: 'z',
            url: 'https://www.example.com/z',
            description: 'Z',
          },
        },
      ],
    });
  });

  it('returns a v1 schema report', () => {
    const report = {
      licenses: [],
      dependencies: [],
    };

    expect(subject.mapFrom(report)).toBe(report);
  });

  it('returns a v1.1 schema report', () => {
    const report = {
      version: '1.1',
      licenses: [],
      dependencies: [],
    };

    expect(subject.mapFrom(report)).toBe(report);
  });

  it('ignores undefined versions', () => {
    const report = {};

    expect(subject.mapFrom(report)).toBe(report);
  });

  it('ignores undefined reports', () => {
    const report = undefined;

    expect(subject.mapFrom(report)).toBe(report);
  });

  it('ignores null reports', () => {
    const report = null;

    expect(subject.mapFrom(report)).toBe(report);
  });
});
