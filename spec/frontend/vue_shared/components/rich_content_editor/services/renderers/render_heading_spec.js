import renderer from '~/vue_shared/components/rich_content_editor/services/renderers/render_heading';
import * as renderUtils from '~/vue_shared/components/rich_content_editor/services/renderers/render_utils';

describe('rich_content_editor/renderers/render_heading', () => {
  it('canRender delegates to renderUtils.canRender', () => {
    expect(renderer.canRender).toBe(renderUtils.canRender);
  });

  it('render delegates to renderUtils.renderWithAttributeDefinitions', () => {
    expect(renderer.render).toBe(renderUtils.renderWithAttributeDefinitions);
  });
});
