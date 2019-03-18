import { __ } from '~/locale';
import { parseUrlPathname, parseUrl } from '../lib/utils/common_utils';

export default () => {
  const shareBtn = document.querySelector('.js-share-btn');

  if (shareBtn) {
    const embedBtn = document.querySelector('.js-embed-btn');
    const snippetUrlArea = document.querySelector('.js-snippet-url-area');
    const embedAction = document.querySelector('.js-embed-action');
    const dataUrl = snippetUrlArea.getAttribute('data-url');

    shareBtn.addEventListener('click', () => {
      shareBtn.classList.add('is-active');
      embedBtn.classList.remove('is-active');
      snippetUrlArea.value = dataUrl;
      embedAction.innerText = __('Share');
    });

    embedBtn.addEventListener('click', () => {
      const parser = parseUrl(dataUrl);
      const url = `${parser.origin + parseUrlPathname(dataUrl)}`;
      const params = parser.search;
      const scriptTag = `<script src="${url}.js${params}"></script>`;

      embedBtn.classList.add('is-active');
      shareBtn.classList.remove('is-active');
      snippetUrlArea.value = scriptTag;
      embedAction.innerText = __('Embed');
    });
  }
};
