import {
  renderDefaultBlock,
  renderEnterExitBlock,
} from '~/vue_shared/components/rich_content_editor/services/renderers/render_utils';

import { uneditableCloseToken } from './mock_data';

describe('Render utils', () => {
  describe('renderDefaultBlock', () => {
    it('should...', () => {
      const context = { origin: jest.fn() };
      const result = renderDefaultBlock({}, context);

      expect(context.origin).toHaveBeenCalled();
      expect(result).toHaveLength(3);
      expect(result[2]).toStrictEqual(uneditableCloseToken);
    });
  });

  describe('renderEnterExitBlock', () => {
    let origin;

    beforeEach(() => {
      origin = jest.fn();
    });

    it('should return two tokens as an array when entering', () => {
      const context = { entering: true, origin };
      const result = renderEnterExitBlock({}, context);

      expect(context.origin).toHaveBeenCalled();
      expect(result).toHaveLength(2);
    });

    it('should return a single closing token as an object when exiting', () => {
      const context = { entering: false, origin };
      const result = renderEnterExitBlock({}, context);

      expect(context.origin).not.toHaveBeenCalled();
      expect(result).toStrictEqual(uneditableCloseToken);
    });
  });
});
