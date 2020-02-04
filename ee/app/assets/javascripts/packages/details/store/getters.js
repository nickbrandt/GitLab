import { s__ } from '~/locale';

export const packageHasPipeline = ({ packageEntity }) => {
  if (packageEntity?.build_info?.pipeline_id) {
    return true;
  }

  return false;
};

export const packageTypeDisplay = ({ packageEntity }) => {
  switch (packageEntity.package_type) {
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
