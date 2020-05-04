import { shallowMount } from '@vue/test-utils';
import PipelineArtifacts from '~/pipelines/components/pipelines_artifacts.vue';
import { GlLink } from '@gitlab/ui';

describe('Pipelines Artifacts dropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineArtifacts, {
      propsData: {
        artifacts: [
          {
            name: 'artifact',
            path: '/download/path',
          },
        ],
      },
    });
  };

  const findGlLink = () => wrapper.find(GlLink);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a dropdown with the provided artifacts', () => {
    expect(wrapper.findAll('[data-testid="artifact"]')).toHaveLength(1);
  });

  it('should render a link with the provided path', () => {
    expect(findGlLink().attributes('href')).toEqual('/download/path');

    expect(findGlLink().text()).toContain('artifact');
  });
});
