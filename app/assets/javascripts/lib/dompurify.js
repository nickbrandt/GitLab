import { sanitize, addHook } from 'dompurify';
import { getBaseURL, relativePathToAbsolute } from '~/lib/utils/url_utility';

// Safely allow SVG <use> tags

const defaultConfig = {
  ADD_TAGS: ['use'],
};

const getIconUrlsRegex = () => {
  const { gon } = window;

  // Only icons urls from `gon` are allowed
  const allowed = [gon.sprite_file_icons, gon.sprite_icons]
    .map(url => relativePathToAbsolute(url, getBaseURL()))
    .filter(url => url);

  if (allowed.length) {
    return allowed.join('|');
  }
  return null; // No urls allowed
};

const removeUnsafeHref = (node, allowedRegex = null, attr = 'href') => {
  if (node.hasAttribute(attr) && !node.getAttribute(attr).match(allowedRegex)) {
    const url = relativePathToAbsolute(node.getAttribute(attr), getBaseURL());
    if (!url.match(allowedRegex)) {
      node.removeAttribute(attr);
    }
  }
};

/**
 * Sanitize icons' <use> tag attributes, to safely include
 * svgs such as in:
 *
 * <svg viewBox="0 0 100 100">
 *   <use href="/assets/icons-xxx.svg#icon_name"></use>
 * </svg>
 *
 * Note: In order to render icons, you should still allow <use>
 * when invoking `sanitize`, for example:
 *
 * ```
 * import { sanitize } from '~/lib/dompurify';
 *
 * sanitize(content, { ADD_TAGS: ['use'] });
 * ```
 *
 * @param {Object} node - Node to sanitize
 */
const sanitizeSvgIcons = node => {
  const allowed = getIconUrlsRegex();

  removeUnsafeHref(node, allowed);

  // Note: `xlink:href` is deprecated
  // https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xlink:href
  removeUnsafeHref(node, allowed, 'xlink:href');
};

addHook('afterSanitizeAttributes', node => {
  if (node.tagName.toLowerCase() === 'use') {
    sanitizeSvgIcons(node);
  }
});

const defaultSanitize = (val, config = defaultConfig) => {
  return sanitize(val, config);
};

export { defaultSanitize as sanitize };
