import { mount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import PackagesApp from 'ee/packages/details/components/app.vue';
import PackageInformation from 'ee/packages/details/components/information.vue';
import PackageInstallation from 'ee/packages/details/components/installation.vue';
import { mavenPackage, mavenFiles, npmPackage, npmFiles } from '../../mock_data';

describe('PackagesApp', () => {
  let wrapper;

  const defaultProps = {
    packageEntity: mavenPackage,
    files: mavenFiles,
    canDelete: true,
    destroyPath: 'destroy-package-path',
    emptySvgPath: 'empty-illustration',
    npmPath: 'foo',
    npmHelpPath: 'foo',
  };

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = mount(PackagesApp, {
      propsData,
      sync: false,
      attachToDocument: true,
    });
  }

  const versionTitle = () => wrapper.find('.js-version-title');
  const emptyState = () => wrapper.find('.js-package-empty-state');
  const allPackageInformation = () => wrapper.findAll(PackageInformation);
  const packageInformation = index => allPackageInformation().at(index);
  const packageInstallation = () => wrapper.find(PackageInstallation);
  const allFileRows = () => wrapper.findAll('.js-file-row');
  const firstFileDownloadLink = () => wrapper.find('.js-file-download');
  const deleteButton = () => wrapper.find('.js-delete-button');
  const deleteModal = () => wrapper.find(GlModal);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the app and displays the package version as the title', () => {
    createComponent();

    expect(versionTitle()).toExist();
    expect(versionTitle().text()).toBe(mavenPackage.version);
  });

  it('renders an empty state component when no an invalid package is passed as a prop', () => {
    createComponent({
      packageEntity: {},
    });

    expect(emptyState()).toExist();
  });

  it('renders package information and metadata for packages containing both information and metadata', () => {
    createComponent();

    expect(packageInformation(0)).toExist();
    expect(packageInformation(1)).toExist();
  });

  it('does not render package metadata for npm as npm packages do not contain metadata', () => {
    createComponent({
      packageEntity: npmPackage,
      files: npmFiles,
    });

    expect(packageInformation(0)).toExist();
    expect(allPackageInformation().length).toBe(1);
  });

  it('renders package installation instructions for npm packages', () => {
    createComponent({
      packageEntity: npmPackage,
      files: npmFiles,
    });

    expect(packageInstallation()).toExist();
  });

  it('does not render package installation instructions for non npm packages', () => {
    createComponent();

    expect(packageInstallation().exists()).toBe(false);
  });

  it('renders a single file for an npm package as they only contain one file', () => {
    createComponent({
      packageEntity: npmPackage,
      files: npmFiles,
    });

    expect(allFileRows()).toExist();
    expect(allFileRows().length).toBe(1);
  });

  it('renders multiple files for a package that contains more than one file', () => {
    createComponent();

    expect(allFileRows()).toExist();
    expect(allFileRows().length).toBe(2);
  });

  it('allows the user to download a package file by rendering a download link', () => {
    createComponent();

    expect(allFileRows()).toExist();
    expect(firstFileDownloadLink().vm.$attrs.href).toContain('download');
  });

  describe('deleting packages', () => {
    beforeEach(() => {
      createComponent();
      deleteButton().trigger('click');
    });

    it('shows the delete confirmation modal when delete is clicked', () => {
      expect(deleteModal()).toExist();
    });
  });
});
