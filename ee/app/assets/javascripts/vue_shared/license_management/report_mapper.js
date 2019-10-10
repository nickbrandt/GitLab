import V1 from './mappers/v1';
import V2 from './mappers/v2';

export default class ReportMapper {
  constructor() {
    this.mappers = { '1': V1, '2': V2 };
  }

  mapFrom(reportArtifact) {
    const majorVersion = ReportMapper.majorVersion(reportArtifact);
    return this.mapperFor(majorVersion).mapFrom(reportArtifact);
  }

  mapperFor(majorVersion) {
    return new this.mappers[majorVersion]();
  }

  static majorVersion(report) {
    return report && report.version ? report.version.split('.')[0] : '1';
  }
}
