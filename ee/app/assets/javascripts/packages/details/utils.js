import { __ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { TrackingActions } from './constants';
import { PackageType } from '../shared/constants';

export const trackInstallationTabChange = {
  methods: {
    trackInstallationTabChange(tabIndex) {
      const action = tabIndex === 0 ? TrackingActions.INSTALLATION : TrackingActions.REGISTRY_SETUP;
      this.track(action);
    },
  },
};

export function generateConanRecipe(packageEntity = {}) {
  const {
    name = '',
    version = '',
    conan_metadatum: {
      package_username: packageUsername = '',
      package_channel: packageChannel = '',
    } = {},
  } = packageEntity;

  return `${name}/${version}@${packageUsername}/${packageChannel}`;
}

export function generatePackageInfo(packageEntity = {}) {
  const information = [];

  if (packageEntity.package_type === PackageType.CONAN) {
    information.push({
      label: __('Recipe'),
      value: generateConanRecipe(packageEntity),
    });
  } else {
    information.push({
      label: __('Name'),
      value: packageEntity.name || '',
    });
  }

  return [
    ...information,
    {
      label: __('Version'),
      value: packageEntity.version || '',
    },
    {
      label: __('Created on'),
      value: formatDate(packageEntity.created_at),
    },
    {
      label: __('Updated at'),
      value: formatDate(packageEntity.updated_at),
    },
  ];
}
