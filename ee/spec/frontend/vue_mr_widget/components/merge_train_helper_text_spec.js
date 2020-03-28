import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import MergeTrainHelperText from 'ee/vue_merge_request_widget/components/merge_train_helper_text.vue';

describe('MergeTrainHelperText', () => {
  let wrapper;

  const factory = propsData => {
    wrapper = shallowMount(MergeTrainHelperText, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should return the "start" version of the message if there is no existing merge train', () => {
    factory({
      pipelineId: 123,
      pipelineLink: 'path/to/pipeline',
      mergeTrainWhenPipelineSucceedsDocsPath: 'path/to/help',
      mergeTrainLength: 0,
    });

    expect(trimText(wrapper.text())).toBe(
      'This merge request will start a merge train when pipeline #123 succeeds. More information',
    );
  });

  it('should render the correct pipeline link in the helper text', () => {
    factory({
      pipelineId: 123,
      pipelineLink: 'path/to/pipeline',
      mergeTrainWhenPipelineSucceedsDocsPath: 'path/to/help',
      mergeTrainLength: 2,
    });

    const pipelineLink = wrapper.find('.js-pipeline-link').element;

    expect(pipelineLink).toExist();
    expect(pipelineLink.textContent).toContain('#123');
    expect(pipelineLink).toHaveAttr('href', 'path/to/pipeline');
  });

  it('should sanitize the pipeline link', () => {
    factory({
      pipelineId: 123,
      pipelineLink: '"></a> <script>console.log("hacked!!")</script> <a href="',
      mergeTrainWhenPipelineSucceedsDocsPath: 'path/to/help',
      mergeTrainLength: 2,
    });

    const pipelineLink = wrapper.find('.js-pipeline-link').element;

    expect(pipelineLink).toExist();

    // The escaped characters are un-escaped when rendered by the DOM,
    // so we expect the value of the "href" attr to be exactly the same
    // as the input.  If the link was not sanitized, the "href" attr
    // would equal "".
    expect(pipelineLink).toHaveAttr(
      'href',
      '"></a> <script>console.log("hacked!!")</script> <a href="',
    );
  });

  it('should render the correct documentation link in the helper text', () => {
    factory({
      pipelineId: 123,
      pipelineLink: 'path/to/pipeline',
      mergeTrainWhenPipelineSucceedsDocsPath: 'path/to/help',
      mergeTrainLength: 2,
    });

    const docLink = wrapper.find(GlLink);

    expect(docLink.exists()).toBe(true);
    expect(docLink.attributes().href).toBe('path/to/help');
  });
});
