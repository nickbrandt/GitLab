import { sanitize } from '~/lib/dompurify';

// GDK
const localGon = {
  sprite_file_icons: '/assets/icons-123a.svg',
  sprite_icons: '/assets/icons-456b.svg',
};

// Production
const absoluteGon = {
  sprite_file_icons: `${window.location.protocol}//${window.location.hostname}/assets/icons-123a.svg`,
  sprite_icons: `${window.location.protocol}//${window.location.hostname}/assets/icons-456b.svg`,
};

describe('~/lib/dompurify', () => {
  let originalGon;

  describe('uses local configuration', () => {
    // As dompurify uses a "Persistent Configuration", it might
    // ignore config, this check verifies we respect
    // https://github.com/cure53/DOMPurify#persistent-configuration
    it('no allowed tags', () => {
      expect(sanitize('<br/>', { ALLOWED_TAGS: [] })).toBe('');
      expect(sanitize('<strong></strong>', { ALLOWED_TAGS: [] })).toBe('');
    });
  });

  describe.each`
    type          | gon
    ${'local'}    | ${localGon}
    ${'absolute'} | ${absoluteGon}
  `('when gon contains $type icon urls', ({ gon }) => {
    beforeAll(() => {
      originalGon = window.gon;
      window.gon = gon;
    });

    afterAll(() => {
      window.gon = originalGon;
    });

    it('sanitizes icons allowing safe xlink:href sprite_file_icons', () => {
      const html = '<svg><use xlink:href="/assets/icons-123a.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe(
        '<svg><use xlink:href="/assets/icons-123a.svg#ellipsis_h"></use></svg>',
      );
    });

    it('sanitizes icons allowing safe href sprite_file_icons', () => {
      const html = '<svg><use href="/assets/icons-123a.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe(
        '<svg><use href="/assets/icons-123a.svg#ellipsis_h"></use></svg>',
      );
    });

    it('sanitizes icons allowing safe href sprite_icons', () => {
      const html = '<svg><use href="/assets/icons-456b.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe(
        '<svg><use href="/assets/icons-456b.svg#ellipsis_h"></use></svg>',
      );
    });

    it('sanitizes icons allowing safe xlink:href sprite_icons', () => {
      const html = '<svg><use xlink:href="/assets/icons-456b.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe(
        '<svg><use xlink:href="/assets/icons-456b.svg#ellipsis_h"></use></svg>',
      );
    });

    it('sanitizes icons disabling unsafe href paths', () => {
      const html = '<svg><use href="/an/evil/url"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });

    it('sanitizes icons disabling unsafe xlink:href paths', () => {
      const html = '<svg><use xlink:href="/an/evil/url"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });

    it('sanitizes icons disabling unsafe href hosts', () => {
      const html = '<svg><use href="https://evil.url/assets/icons-123a.svg"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });

    it('sanitizes icons disabling unsafe xlink:href hosts', () => {
      const html = '<svg><use xlink:href="https://evil.url/assets/icons-123a.svg"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });
  });

  describe('when gon does not contain icon urls', () => {
    beforeAll(() => {
      originalGon = window.gon;

      window.gon = {};
    });

    afterAll(() => {
      window.gon = originalGon;
    });

    it('sanitizes icons disabling all xlink:href values', () => {
      const html = '<svg><use xlink:href="/assets/icons-123a.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });

    it('sanitizes icons disabling all href values', () => {
      const html = '<svg><use href="/assets/icons-123a.svg#ellipsis_h"></use></svg>';

      expect(sanitize(html, { ADD_TAGS: ['use'] })).toBe('<svg><use></use></svg>');
    });
  });
});
