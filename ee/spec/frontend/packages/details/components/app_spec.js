import { mount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import Tracking from '~/tracking';
import PackagesApp from 'ee/packages/details/components/app.vue';
import PackageInformation from 'ee/packages/details/components/information.vue';
import NpmInstallation from 'ee/packages/details/components/npm_installation.vue';
import MavenInstallation from 'ee/packages/details/components/maven_installation.vue';
import * as SharedUtils from 'ee/packages/shared/utils';
import { TrackingActions } from 'ee/packages/shared/constants';
import { mavenPackage, mavenFiles, npmPackage, npmFiles, conanPackage } from '../../mock_data';

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
    mavenPath: 'foo',
    mavenHelpPath: 'foo',
  };

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = mount(PackagesApp, {
      propsData,
      attachToDocument: true,
    });
  }

  const versionTitle = () => wrapper.find('.js-version-title');
  const emptyState = () => wrapper.find('.js-package-empty-state');
  const allPackageInformation = () => wrapper.findAll(PackageInformation);
  const packageInformation = index => allPackageInformation().at(index);
  const npmInstallation = () => wrapper.find(NpmInstallation);
  const mavenInstallation = () => wrapper.find(MavenInstallation);
  const allFileRows = () => wrapper.findAll('.js-file-row');
  const firstFileDownloadLink = () => wrapper.find('.js-file-download');
  const deleteButton = () => wrapper.find('.js-delete-button');
  const deleteModal = () => wrapper.find(GlModal);
  const modalDeleteButton = () => wrapper.find({ ref: 'modal-delete-button' });

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

  it('renders package installation instructions for maven packages', () => {
    createComponent();

    expect(mavenInstallation()).toExist();
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

    expect(npmInstallation()).toExist();
  });

  it('does not render package installation instructions for non npm packages', () => {
    createComponent();

    expect(npmInstallation().exists()).toBe(false);
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

  describe('tracking', () => {
    let eventSpy;
    let utilSpy;
    const category = 'foo';

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      utilSpy = jest.spyOn(SharedUtils, 'packageTypeToTrackCategory').mockReturnValue(category);
    });

    it('tracking category calls packageTypeToTrackCategory', () => {
      createComponent({ packageEntity: conanPackage });
      expect(wrapper.vm.tracking.category).toBe(category);
      expect(utilSpy).toHaveBeenCalledWith('conan');
    });

    it(`delete button on delete modal call event with ${TrackingActions.DELETE_PACKAGE}`, () => {
      createComponent({ packageEntity: conanPackage, canDelete: true, destroyPath: 'foo' });
      deleteButton().trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        modalDeleteButton().trigger('click');
        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.DELETE_PACKAGE,
          expect.any(Object),
        );
      });
    });

    it(`file download link call event with ${TrackingActions.PULL_PACKAGE}`, () => {
      createComponent({ packageEntity: conanPackage });
      firstFileDownloadLink().trigger('click');
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        TrackingActions.PULL_PACKAGE,
        expect.any(Object),
      );
    });
  });
});
