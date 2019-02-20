/* eslint-disable no-script-url */
import isSafeURL from 'ee/vue_shared/components/is_safe_url';

describe('isSafeUrl', () => {
  const absoluteUrls = [
    'http://example.org',
    'http://example.org:8080',
    'https://example.org',
    'https://example.org:8080',
    'https://192.168.1.1',
  ];

  const relativeUrls = ['./relative/link', '/relative/link', '../relative/link'];

  const urlsWithoutHost = ['http://', 'https://', 'https:https:https:'];

  const nonHttpUrls = [
    'javascript:',
    'javascript:alert("XSS")',
    'jav\tascript:alert("XSS");',
    ' &#14;  javascript:alert("XSS");',
    'ftp://192.168.1.1',
    'file:///',
    'file:///etc/hosts',
  ];

  const encodedJavaScriptUrls = [
    '&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041',
    '&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;',
    '&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29',
    '\\u006A\\u0061\\u0076\\u0061\\u0073\\u0063\\u0072\\u0069\\u0070\\u0074\\u003A\\u0061\\u006C\\u0065\\u0072\\u0074\\u0028\\u0027\\u0058\\u0053\\u0053\\u0027\\u0029',
  ];

  describe('with URL constructor support', () => {
    it.each(absoluteUrls)('returns true for %s', url => {
      expect(isSafeURL(url)).toBe(true);
    });

    it.each([...relativeUrls, ...urlsWithoutHost, ...nonHttpUrls, ...encodedJavaScriptUrls])(
      'returns false for %s',
      url => {
        expect(isSafeURL(url)).toBe(false);
      },
    );
  });

  describe('without URL constructor support', () => {
    beforeEach(() => {
      jest.spyOn(window, 'URL').mockImplementation(() => {
        throw new Error('No URL support');
      });
    });

    it.each(absoluteUrls)('returns true for %s', url => {
      expect(isSafeURL(url)).toBe(true);
    });

    it.each([...relativeUrls, ...urlsWithoutHost, ...nonHttpUrls, ...encodedJavaScriptUrls])(
      'returns false for %s',
      url => {
        expect(isSafeURL(url)).toBe(false);
      },
    );
  });
});
