import getters from '~/boards/stores/getters';

describe('Boards - Getters', () => {
  describe('getSnowplowLabelToggleState', () => {
    it('should return "on" when isShowingLabels is true', () => {
      const state = {
        isShowingLabels: true,
      };

      expect(getters.getSnowplowLabelToggleState(state)).toBe('on');
    });

    it('should return "off" when isShowingLabels is false', () => {
      const state = {
        isShowingLabels: false,
      };

      expect(getters.getSnowplowLabelToggleState(state)).toBe('off');
    });
  });
});
