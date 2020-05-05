import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState, GlModal } from '@gitlab/ui';
import Tracking from '~/tracking';
import * as getters from 'ee/packages/details/store/getters';
import PackagesApp from 'ee/packages/details/components/app.vue';
import PackageTitle from 'ee/packages/details/components/package_title.vue';
import PackageInformation from 'ee/packages/details/components/information.vue';
import NpmInstallation from 'ee/packages/details/components/npm_installation.vue';
import MavenInstallation from 'ee/packages/details/components/maven_installation.vue';
import * as SharedUtils from 'ee/packages/shared/utils';
import { TrackingActions } from 'ee/packages/shared/constants';
import ConanInstallation from 'ee/packages/details/components/conan_installation.vue';
import NugetInstallation from 'ee/packages/details/components/nuget_installation.vue';
import PypiInstallation from 'ee/packages/details/components/pypi_installation.vue';
import {
  conanPackage,
  mavenPackage,
  mavenFiles,
  npmPackage,
  npmFiles,
  nugetPackage,
  pypiPackage,
} from '../../mock_data';
import stubChildren from 'helpers/stub_children';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackagesApp', () => {
  let wrapper;
  let store;

  function createComponent(packageEntity = mavenPackage, packageFiles = mavenFiles) {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        packageEntity,
        packageFiles,
        canDelete: true,
        destroyPath: 'destroy-package-path',
        emptySvgPath: 'empty-illustration',
        npmPath: 'foo',
        npmHelpPath: 'foo',
      },
      getters,
    });

    wrapper = mount(PackagesApp, {
      localVue,
      store,
      stubs: {
        ...stubChildren(PackagesApp),
        GlDeprecatedButton: false,
        GlLink: false,
        GlModal: false,
        GlTable: false,
      },
    });
  }

  const packageTitle = () => wrapper.find(PackageTitle);
  const emptyState = () => wrapper.find(GlEmptyState);
  const allPackageInformation = () => wrapper.findAll(PackageInformation);
  const packageInformation = index => allPackageInformation().at(index);
  const npmInstallation = () => wrapper.find(NpmInstallation);
  const mavenInstallation = () => wrapper.find(MavenInstallation);
  const conanInstallation = () => wrapper.find(ConanInstallation);
  const nugetInstallation = () => wrapper.find(NugetInstallation);
  const pypiInstallation = () => wrapper.find(PypiInstallation);
  const allFileRows = () => wrapper.findAll('.js-file-row');
  const firstFileDownloadLink = () => wrapper.find('.js-file-download');
  const deleteButton = () => wrapper.find('.js-delete-button');
  const deleteModal = () => wrapper.find(GlModal);
  const modalDeleteButton = () => wrapper.find({ ref: 'modal-delete-button' });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the app and displays the package title', () => {
    createComponent();

    expect(packageTitle()).toExist();
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
    createComponent(npmPackage, npmFiles);

    expect(packageInformation(0)).toExist();
    expect(allPackageInformation()).toHaveLength(1);
  });

  describe('installation instructions', () => {
    describe.each`
      packageEntity   | selector
      ${conanPackage} | ${conanInstallation}
      ${mavenPackage} | ${mavenInstallation}
      ${npmPackage}   | ${npmInstallation}
      ${nugetPackage} | ${nugetInstallation}
      ${pypiPackage}  | ${pypiInstallation}
    `('renders', ({ packageEntity, selector }) => {
      it(`${packageEntity.package_type} instructions`, () => {
        createComponent({ packageEntity });

        expect(selector()).toExist();
      });
    });
  });

  it('renders a single file for an npm package as they only contain one file', () => {
    createComponent(npmPackage, npmFiles);

    expect(allFileRows()).toExist();
    expect(allFileRows()).toHaveLength(1);
  });

  it('renders multiple files for a package that contains more than one file', () => {
    createComponent();

    expect(allFileRows()).toExist();
    expect(allFileRows()).toHaveLength(2);
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
      createComponent(conanPackage);
      expect(wrapper.vm.tracking.category).toBe(category);
      expect(utilSpy).toHaveBeenCalledWith('conan');
    });

    it(`delete button on delete modal call event with ${TrackingActions.DELETE_PACKAGE}`, () => {
      createComponent(conanPackage);
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
      createComponent(conanPackage);
      firstFileDownloadLink().trigger('click');
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        TrackingActions.PULL_PACKAGE,
        expect.any(Object),
      );
    });
  });
});
