import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import PackageInformation from 'ee/packages/details/components/information.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { npmPackage, mavenPackage as packageWithoutBuildInfo } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackageInformation', () => {
  let wrapper;
  let store;

  const defaultProps = {
    information: [
      {
        label: 'Information one',
        value: 'Information value one',
      },
      {
        label: 'Information two',
        value: 'Information value two',
      },
      {
        label: 'Information three',
        value: 'Information value three',
      },
    ],
  };

  function createComponent(
    props = {},
    packageEntity = packageWithoutBuildInfo,
    hasPipeline = false,
    isLoading = false,
    pipelineError = null,
  ) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    store = new Vuex.Store({
      state: {
        isLoading,
        packageEntity,
        pipelineInfo: {},
        pipelineError,
      },
      getters: {
        packageHasPipeline: () => hasPipeline,
      },
    });

    wrapper = shallowMount(PackageInformation, {
      localVue,
      propsData,
      store,
    });
  }

  const headingSelector = () => wrapper.find('.card-header > strong');
  const copyButton = () => wrapper.findAll(ClipboardButton);
  const informationSelector = () => wrapper.findAll('ul.content-list li');
  const informationRowText = index =>
    informationSelector()
      .at(index)
      .text();
  const packagePipelineInfoListItem = () => wrapper.find('.js-package-pipeline');
  const pipelineLoader = () => wrapper.find(GlLoadingIcon);
  const pipelineErrorMessage = () => wrapper.find('.js-pipeline-error');
  const pipelineInfoContent = () => wrapper.find('.js-pipeline-info');

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('renders the information block with default heading', () => {
    createComponent();

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe('Package information');
  });

  it('renders a custom supplied heading', () => {
    const heading = 'A custom heading';

    createComponent({
      heading,
    });

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe(heading);
  });

  it('renders the supplied information', () => {
    createComponent();

    expect(informationSelector().length).toBe(3);
    expect(informationRowText(0)).toContain('one');
    expect(informationRowText(1)).toContain('two');
    expect(informationRowText(2)).toContain('three');
  });

  describe('copy button', () => {
    it('does not render by default', () => {
      createComponent();

      expect(copyButton().exists()).toBe(false);
    });

    it('does render when the prop is set and has correct text set', () => {
      createComponent({ showCopy: true });

      expect(copyButton().length).toBe(3);
      expect(copyButton().at(0).vm.text).toBe(defaultProps.information[0].value);
      expect(copyButton().at(1).vm.text).toBe(defaultProps.information[1].value);
      expect(copyButton().at(2).vm.text).toBe(defaultProps.information[2].value);
    });
  });

  describe('pipeline information', () => {
    it('does not display pipeline information when no build info is available', () => {
      createComponent();

      expect(packagePipelineInfoListItem().exists()).toBe(false);
    });

    it('displays the loading spinner when fetching information', () => {
      createComponent({}, npmPackage, true, true);

      expect(packagePipelineInfoListItem().exists()).toBe(true);
      expect(pipelineLoader().exists()).toBe(true);
    });

    it('displays that the pipeline error information fetching fails', () => {
      const pipelineError = 'an-error-message';
      createComponent({}, npmPackage, true, false, pipelineError);

      expect(packagePipelineInfoListItem().exists()).toBe(true);
      expect(pipelineLoader().exists()).toBe(false);
      expect(pipelineErrorMessage().exists()).toBe(true);
      expect(pipelineErrorMessage().text()).toBe(pipelineError);
    });

    it('displays the pipeline information if found', () => {
      createComponent({}, npmPackage, true);

      expect(packagePipelineInfoListItem().exists()).toBe(true);
      expect(pipelineInfoContent().exists()).toBe(true);
    });
  });
});
