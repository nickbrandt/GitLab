import { s__ } from '~/locale';

const checkFeatureFlag = glFeatures => ([, { featureFlag }]) => {
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
      featureFlag: 'onDemandScansScannerProfiles',
      i18n: {
        title: s__('DastProfiles|Scanner Profile'),
      },
    },
  };

  return Object.fromEntries(Object.entries(settings).filter(checkFeatureFlag(glFeatures)));
}
