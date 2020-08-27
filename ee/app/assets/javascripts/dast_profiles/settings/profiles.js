import { s__ } from '~/locale';

const hasNoFeatureFlagOrEnabled = glFeatures => ([, { featureFlag }]) => {
  if (!featureFlag) {
    return true;
  }

  return Boolean(glFeatures[featureFlag]);
};

export default function({ glFeatures, options: { createNewProfilePaths } = {} }) {
  const settings = {
    siteProfiles: {
      key: 'siteProfiles',
      createNewProfilePath: createNewProfilePaths.siteProfile,
      i18n: {
        title: s__('DastProfiles|Site Profile'),
      },
    },
    scannerProfiles: {
      key: 'scannerProfiles',
      createNewProfilePath: createNewProfilePaths.scannerProfile,
      featureFlag: 'securityOnDemandScansScannerProfiles',
      i18n: {
        title: s__('DastProfiles|Scanner Profile'),
      },
    },
  };

  return Object.fromEntries(Object.entries(settings).filter(hasNoFeatureFlagOrEnabled(glFeatures)));
}
