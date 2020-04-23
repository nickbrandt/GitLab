import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import PackageTitle from 'ee/packages/details/components/package_title.vue';
import PackageTags from 'ee/packages/shared/components/package_tags.vue';
import {
  conanPackage,
  mavenFiles,
  mavenPackage,
  mockTags,
  npmFiles,
  npmPackage,
  nugetPackage,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackageTitle', () => {
  let wrapper;
  let store;

  function createComponent(packageEntity = mavenPackage, packageFiles = mavenFiles) {
    store = new Vuex.Store({
      state: {
        packageEntity,
        packageFiles,
      },
      getters: {
        packageTypeDisplay: ({ packageEntity: { package_type: type } }) => type,
        packagePipeline: ({ packageEntity: { pipeline = null } }) => pipeline,
      },
    });

    wrapper = shallowMount(PackageTitle, {
      localVue,
      store,
    });
  }

  const packageType = () => wrapper.find({ ref: 'package-type' });
  const packageSize = () => wrapper.find({ ref: 'package-size' });
  const pipelineProject = () => wrapper.find({ ref: 'pipeline-project' });
  const packageRef = () => wrapper.find({ ref: 'package-ref' });
  const packageTags = () => wrapper.find(PackageTags);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    it('without tags', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('with tags', () => {
      createComponent({ ...mavenPackage, tags: mockTags });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe.each`
    packageEntity   | expectedResult
    ${conanPackage} | ${'conan'}
    ${mavenPackage} | ${'maven'}
    ${npmPackage}   | ${'npm'}
    ${nugetPackage} | ${'nuget'}
  `(`package type`, ({ packageEntity, expectedResult }) => {
    beforeEach(() => createComponent(packageEntity));

    it(`${packageEntity.package_type} should render from Vuex getters ${expectedResult}`, () => {
      expect(packageType().text()).toBe(expectedResult);
    });
  });

  describe('calculates the package size', () => {
    it('correctly calulates when there is only 1 file', () => {
      createComponent(npmPackage, npmFiles);

      expect(packageSize().text()).toBe('200 bytes');
    });

    it('correctly calulates when there are multiple files', () => {
      createComponent();

      expect(packageSize().text()).toBe('300 bytes');
    });
  });

  describe('package tags', () => {
    it('displays the package-tags component when the package has tags', () => {
      createComponent({
        ...npmPackage,
        tags: mockTags,
      });

      expect(packageTags().exists()).toBe(true);
    });

    it('does not display the package-tags component when there are no tags', () => {
      createComponent();

      expect(packageTags().exists()).toBe(false);
    });
  });

  describe('package ref', () => {
    it('does not display the ref if missing', () => {
      createComponent();

      expect(packageRef().exists()).toBe(false);
    });

    it('correctly shows the package ref if there is one', () => {
      createComponent(npmPackage);

      expect(packageRef().contains('gl-icon-stub')).toBe(true);
      expect(packageRef().text()).toBe(npmPackage.pipeline.ref);
    });
  });

  describe('pipeline project', () => {
    it('does not display the project if missing', () => {
      createComponent();

      expect(pipelineProject().exists()).toBe(false);
    });

    it('correctly shows the pipeline project if there is one', () => {
      createComponent(npmPackage);

      expect(pipelineProject().text()).toBe(npmPackage.pipeline.project.name);
      expect(pipelineProject().attributes('href')).toBe(npmPackage.pipeline.project.web_url);
    });
  });
});
