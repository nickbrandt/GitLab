import V2Report from './v2_report';

const DEFAULT_VERSION = '1';

export default class ReportMapper {
  constructor() {
    this.mappers = {
      '1': report => report,
      '2': report => new V2Report(report).toV1Schema(),
    };
  }

  mapFrom(reportArtifact) {
    const majorVersion = ReportMapper.majorVersionFor(reportArtifact);
    return this.mapperFor(majorVersion)(reportArtifact);
  }

  mapperFor(majorVersion) {
    return this.mappers[majorVersion];
  }

  static majorVersionFor(report) {
    if (report && report.version) {
      const [majorVersion] = report.version.split('.');
      return majorVersion;
    }

    return DEFAULT_VERSION;
  }
}
