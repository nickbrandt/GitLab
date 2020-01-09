import { packageTypeToTrackCategory } from 'ee/packages/shared/utils';
import { PackageType, TrackingCategories } from 'ee/packages/shared/constants';

describe('Packages shared utils', () => {
  describe('packageTypeToTrackCategory', () => {
    it('prepend UI to package category', () => {
      expect(packageTypeToTrackCategory()).toMatchInlineSnapshot(`"UI::undefined"`);
    });

    it.each(Object.keys(PackageType))('returns a correct category string for %s', packageKey => {
      const packageName = PackageType[packageKey];
      expect(packageTypeToTrackCategory(packageName)).toBe(
        `UI::${TrackingCategories[packageName]}`,
      );
    });
  });
});
