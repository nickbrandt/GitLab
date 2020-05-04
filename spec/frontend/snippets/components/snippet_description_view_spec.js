import SnippetDescription from '~/snippets/components/snippet_description_view.vue';
import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';

describe('Snippet Description component', () => {
  let wrapper;
  const description = '<h2>The property of Thor</h2>';
  let renderGFMSpy;

  function createComponent() {
    wrapper = shallowMount(SnippetDescription, {
      propsData: {
        description,
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

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('processes rendering with GFM', () => {
    expect(renderGFMSpy).toHaveBeenCalled();
  });
});
