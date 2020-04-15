import { s__ } from '~/locale';
import { TrackingCategories } from './constants';

export const packageTypeToTrackCategory = type =>
  // eslint-disable-next-line @gitlab/require-i18n-strings
  `UI::${TrackingCategories[type]}`;

export const beautifyPath = path => (path ? path.split('/').join(' / ') : '');

export const getPackageType = packageType => {
  switch (packageType) {
    case 'conan':
      return s__('PackageType|Conan');
    case 'maven':
      return s__('PackageType|Maven');
    case 'npm':
      return s__('PackageType|NPM');
    case 'nuget':
      return s__('PackageType|NuGet');

    default:
      return null;
  }
};
