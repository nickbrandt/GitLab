import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLink, GlSkeletonLoading } from '@gitlab/ui';
import LicenseComponentLinks from 'ee/project_licenses/components/license_component_links.vue';
import LicensesTableRow from 'ee/project_licenses/components/licenses_table_row.vue';
import { makeLicense } from './utils';

describe('LicensesTableRow component', () => {
  const localVue = createLocalVue();
  let wrapper;
  let license;

  const factory = (propsData = {}) => {
    wrapper = shallowMount(localVue.extend(LicensesTableRow), {
      localVue,
      sync: false,
      propsData,
    });
  };

  const findLoading = () => wrapper.find(GlSkeletonLoading);
  const findContent = () => wrapper.find('.js-license-row');
  const findNameSeciton = () => findContent().find('.section-30');
  const findComponentSection = () => findContent().find('.section-70');

  beforeEach(() => {
    license = makeLicense();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    desc                      | props
    ${'when passed no props'} | ${{}}
    ${'when loading'}         | ${{ isLoading: true }}
  `('$desc', ({ props }) => {
    beforeEach(() => {
      factory(props);
    });

    it('shows the skeleton loading component', () => {
      const loading = findLoading();

      expect(loading.exists()).toBe(true);
      expect(loading.props('lines')).toEqual(1);
    });

    it('does not show the content', () => {
      const content = findContent();

      expect(content.exists()).toBe(false);
    });
  });

  describe('when a license has url and components', () => {
    beforeEach(() => {
      factory({
        isLoading: false,
        license,
      });
    });

    it('shows name', () => {
      const nameLink = findNameSeciton().find(GlLink);

      expect(nameLink.exists()).toBe(true);
      expect(nameLink.attributes('href')).toEqual(license.url);
      expect(nameLink.text()).toEqual(license.name);
    });

    it('shows components', () => {
      const componentLinks = findComponentSection().find(LicenseComponentLinks);

      expect(componentLinks.exists()).toBe(true);
      expect(componentLinks.props()).toEqual(
        expect.objectContaining({
          components: license.components,
          title: license.name,
        }),
      );
    });
  });

  describe('with a license without a url', () => {
    beforeEach(() => {
      license.url = null;

      factory({
        isLoading: false,
        license,
      });
    });

    it('does not show url link for name', () => {
      const nameSection = findNameSeciton();

      expect(nameSection.text()).toContain(license.name);
      expect(nameSection.find(GlLink).exists()).toBe(false);
    });
  });
});
