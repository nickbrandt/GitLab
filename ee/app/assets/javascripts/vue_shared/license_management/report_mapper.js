import V1 from './mappers/v1';
import V2 from './mappers/v2';
import FeatureFlag from '~/lib/feature_flag';

const MAPPERS = { '1': V1, '2': V2 };

export default class ReportMapper {
  constructor(featureEnabled = FeatureFlag.isEnabled('licenseScanV2')) {
    this.featureEnabled = featureEnabled;
  }

  mapFrom(reportArtifact) {
    const majorVersion = ReportMapper.majorVersion(reportArtifact);
    return this.mapperFor(majorVersion).mapFrom(reportArtifact);
  }

  mapperFor(majorVersion) {
    if (this.featureEnabled || majorVersion === '2') {
      return new MAPPERS[majorVersion]();
    }
    return new V1();
  }

  static majorVersion(report) {
    return report && report.version ? report.version.split('.')[0] : '1';
  }
}
