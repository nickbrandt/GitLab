import ReportMapper from 'ee/vue_shared/license_management/report_mapper';
import { Builder } from '../../license_management/mock_data';

describe('mapFrom', () => {
  let subject = null;

  beforeEach(() => {
    subject = new ReportMapper(true);
  });

  it('converts a v2 schema report to v1.1', () => {
    const report = Builder.forV2()
      .addLicense({ id: 'MIT', name: 'MIT License' })
      .addLicense({ id: 'BSD', name: 'BSD License' })
      .addDependency({ name: 'x', licenses: ['MIT'] })
      .addDependency({ name: 'y', licenses: ['BSD'] })
      .addDependency({ name: 'z', licenses: ['BSD', 'MIT'] })
      .build();

    const result = subject.mapFrom(report);
    expect(result).toMatchObject(
      Builder.forV1('1')
        .addLicense({ name: 'BSD License', count: 2 })
        .addLicense({ name: 'MIT License', count: 2 })
        .addDependency({ name: 'x', license: { name: 'MIT License' } })
        .addDependency({ name: 'y', license: { name: 'BSD License' } })
        .addDependency({
          name: 'z',
          license: { name: 'BSD License, MIT License', url: '' },
          licenses: [{ name: 'BSD License' }, { name: 'MIT License' }],
        })
        .build(),
    );
  });

  it('returns a v1 schema report', () => {
    const report = Builder.forV1().build();

    expect(subject.mapFrom(report)).toBe(report);
  });

  it('returns a v1.1 schema report', () => {
    const report = Builder.forV1().build({ version: '1.1' });

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
