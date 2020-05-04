import { shallowMount } from '@vue/test-utils';
import RichViewer from '~/vue_shared/components/blob_viewers/rich_viewer.vue';
import { handleBlobRichViewer } from '~/blob/viewer';
import $ from 'jquery';

jest.mock('~/blob/viewer');

describe('Blob Rich Viewer component', () => {
  let wrapper;
  const content = '<h1 id="markdown">Foo Bar</h1>';
  const defaultType = 'markdown';

  let renderGFMSpy;

  function createComponent(type = defaultType) {
    wrapper = shallowMount(RichViewer, {
      propsData: {
        content,
        type,
      },
    });
  }

  beforeEach(() => {
    renderGFMSpy = jest.spyOn($.fn, 'renderGFM');
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the passed content without transformations', () => {
    expect(wrapper.html()).toContain(content);
  });

  it('queries for advanced viewer', () => {
    expect(handleBlobRichViewer).toHaveBeenCalledWith(expect.anything(), defaultType);
  });

  it('processes rendering with GFM', () => {
    expect(renderGFMSpy).toHaveBeenCalled();
  });
});
