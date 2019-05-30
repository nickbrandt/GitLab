import * as cu from '~/lib/utils/common_utils';

const CMD_ENTITY = '&#8984;';

let platform;
Object.defineProperty(navigator, 'platform', {
  configurable: true,
  get: () => platform,
  set: val => {
    platform = val;
  },
});

describe('common_utils', () => {
  describe('platform leader key helpers', () => {
    const CTRL_EVENT = { ctrlKey: true };
    const META_EVENT = { metaKey: true };
    const BOTH_EVENT = { ctrlKey: true, metaKey: true };

    it('should return "ctrl" if navigator.platform is unset', () => {
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "meta" on MacOS', () => {
      navigator.platform = 'MacIntel';
      expect(cu.getPlatformLeaderKey()).toBe('meta');
      expect(cu.getPlatformLeaderKeyHTML()).toBe(CMD_ENTITY);
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Linux', () => {
      navigator.platform = 'Linux is great';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });

    it('should return "ctrl" on Windows', () => {
      navigator.platform = 'Win32';
      expect(cu.getPlatformLeaderKey()).toBe('ctrl');
      expect(cu.getPlatformLeaderKeyHTML()).toBe('Ctrl');
      expect(cu.isPlatformLeaderKey(CTRL_EVENT)).toBe(true);
      expect(cu.isPlatformLeaderKey(META_EVENT)).toBe(false);
      expect(cu.isPlatformLeaderKey(BOTH_EVENT)).toBe(true);
    });
  });

  describe('keystroke', () => {
    // Helper function that quickly creates KeyboardEvents
    const k = str => {
      const [modifiers, key] = str.split('-');
      if (!key) return { key: modifiers };
      return {
        key,
        altKey: modifiers.includes('a'),
        ctrlKey: modifiers.includes('c'),
        metaKey: modifiers.includes('m'),
        shiftKey: modifiers.includes('s'),
      };
    };

    const { keystroke } = cu;

    it('short-circuits with bad arguments', () => {
      expect(keystroke()).toBe(false);
      expect(keystroke({})).toBe(false);
      expect(keystroke({}, '')).toBe(false);
    });

    it('handles keystrokes using key strings', () => {
      expect(keystroke(k('f'), 'f')).toBe(true);
      expect(keystroke(k('Tab'), 'Tab')).toBe(true);
      expect(keystroke(k(' '), 'Space')).toBe(true);
      expect(keystroke(k('Enter'), 'Enter')).toBe(true);
      expect(keystroke(k('`'), '`')).toBe(true);
      expect(keystroke(k('s-f'), 'Shift-F')).toBe(true);
      expect(keystroke(k('s-f'), 'Shift+F')).toBe(true);
      expect(keystroke(k('scma-f'), 'Shift+Ctrl+Meta+Alt+F')).toBe(true);
      expect(keystroke(k('s-$'), 'Shift+$')).toBe(true);
      expect(keystroke(k('m-8'), 'Meta-8')).toBe(true);
    });

    it('is case-insensitive', () => {
      expect(keystroke(k('f'), 'f')).toBe(true);
      expect(keystroke(k('f'), 'F')).toBe(true);
      expect(keystroke(k('s-f'), 'shift-f')).toBe(true);
      expect(keystroke(k('s-f'), 'Shift-F')).toBe(true);
      expect(keystroke(k('s-f'), 'SHIFT-F')).toBe(true);
    });

    it('handles bogus inputs', () => {
      expect(keystroke(k('z'), 'not a keystroke')).toBe(false);
      expect(keystroke(k('z'), 'zz')).toBe(false);
      expect(keystroke(k('z'), 'z/Shift')).toBe(false);
    });

    it('handles exact modifier keys, in any order', () => {
      expect(keystroke(k('smc-f'), 'Shift-Meta-Control-F')).toBe(true);
      expect(keystroke(k('smc-f'), 'Control-Shift-Meta-F')).toBe(true);
      expect(keystroke(k('smc-f'), 'Meta-Shift-Control-F')).toBe(true);
      expect(keystroke(k('smc-f'), 'F-Meta-Shift-Control')).toBe(true);
      expect(keystroke(k('smc-f'), 'Meta-F-Shift-Control')).toBe(true);
      expect(keystroke(k('smc-f'), 'Meta-Shift-F-Control')).toBe(true);
      expect(keystroke(k('smc-f'), 'Shift-Meta-F')).toBe(false);
      expect(keystroke(k('smc-f'), 'Meta-Shift-Alt-F')).toBe(false);
      expect(keystroke(k('smc-f'), 'Shift-Meta-Control-Alt-F')).toBe(false);
    });

    it('handles escaping the plus, minus, and control characters', () => {
      expect(keystroke(k('+'), 'Plus')).toBe(true);
      expect(keystroke(k('s-+'), 'Shift-Plus')).toBe(true);

      expect(keystroke({ key: '-' }, 'Minus')).toBe(true);
      expect(keystroke({ key: '-', metaKey: true }, 'Meta-Minus')).toBe(true);

      expect(keystroke(k('c-f'), 'Ctrl-F')).toBe(true);
      expect(keystroke(k('cs-f'), 'Ctrl-Shift-F')).toBe(true);
    });

    it('handles the platform-dependent leader key', () => {
      navigator.platform = 'Win32';
      expect(keystroke(k('c-f'), 'Leader-F')).toBe(true);
      expect(keystroke(k('m-f'), 'Leader-F')).toBe(false);
      expect(keystroke(k('csa-F'), 'Leader-Shift-Alt-F')).toBe(true);
      expect(keystroke(k('msa-f'), 'Leader-Shift-Alt-F')).toBe(false);

      navigator.platform = 'MacIntel';
      expect(keystroke(k('c-f'), 'Leader-F')).toBe(false);
      expect(keystroke(k('m-f'), 'Leader-F')).toBe(true);
      expect(keystroke(k('csa-F'), 'Leader-Shift-Alt-F')).toBe(false);
      expect(keystroke(k('msa-f'), 'Leader-Shift-Alt-F')).toBe(true);
    });
  });
});
