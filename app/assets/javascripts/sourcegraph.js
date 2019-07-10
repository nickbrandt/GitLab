/**
 * Loads the Sourcegraph integration for support for Sourcegraph extensions and
 * code intelligence.
 */
export default function initSourcegraph() {
  const sourcegraphUrl = gon.sourcegraph_url;
  const assetsUrl = new URL('/assets/webpack/sourcegraph/', window.location.href);
  window.SOURCEGRAPH_ASSETS_URL = assetsUrl.href;
  window.SOURCEGRAPH_URL = sourcegraphUrl;
  window.SOURCEGRAPH_INTEGRATION = 'gitlab-integration';
  // inject a <script> tag to fetch the main JS bundle from the Sourcegraph instance
  const script = document.createElement('script');
  script.type = 'application/javascript';
  script.src = new URL('scripts/integration.bundle.js', assetsUrl).href;
  script.defer = true;
  document.head.appendChild(script);
}
