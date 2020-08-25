import { s__ } from '~/locale';

const hasNoFeatureFlagOrEnabled = glFeatures => ([, { featureFlag }]) => {
  if (!featureFlag) {
    return true;
  }

  return glFeatures[featureFlag];
};

export default function({ glFeatures, options: { newProfilePaths } = {} }) {
  const settings = {
    siteProfiles: {
      key: 'siteProfiles',
      newProfilePath: newProfilePaths.siteProfile,
      i18n: {
        title: s__('DastProfiles|Site Profile'),
      },
    },
    scannerProfiles: {
      key: 'scannerProfiles',
      newProfilePath: newProfilePaths.scannerProfile,
      featureFlag: 'securityOnDemandScansScannerProfiles',
      i18n: {
        title: s__('DastProfiles|Scanner Profile'),
      },
    },
  };

  return Object.fromEntries(Object.entries(settings).filter(hasNoFeatureFlagOrEnabled(glFeatures)));
}
