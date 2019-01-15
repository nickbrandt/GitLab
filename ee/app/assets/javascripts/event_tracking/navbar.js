import Stats from 'ee/stats';
import { mergeUrlParams } from '~/lib/utils/url_utility';

export default function trackNavbarEvents() {
  const container = '.navbar-gitlab';
  const category = 'navbar_top';
  const navbar = document.querySelector('.navbar-gitlab');

  /**
   * intercepts clicks on navbar links
   * and adds the 'nav_source=navbar' query parameter
   */
  const appendLinkParam = e => {
    const NAVSOURCE_KEY = 'nav_source';
    const NAVSOURCE_VALUE = 'navbar';
    const target = e.target || e.srcElement;

    // get closest link in case the target is a wrapping DOM node
    const link = target.tagName === 'A' ? target : target.closest('a');

    if (link && link.href && link.href.indexOf(`${NAVSOURCE_KEY}=${NAVSOURCE_VALUE}`) === -1) {
      const url = mergeUrlParams({ [NAVSOURCE_KEY]: NAVSOURCE_VALUE }, link.href);
      link.setAttribute('href', url);
    }
  };

  Stats.bindTrackableContainer(container, category);

  if (Stats.snowplowEnabled) {
    // track search inputs within frequent-items component
    document
      .querySelectorAll(`${container} .frequent-items-dropdown-container input`)
      .forEach(element => {
        element.addEventListener('click', e => {
          const target = e.currentTarget;
          const parentDropdown = target.closest('li.dropdown');
          const label = `${parentDropdown.getAttribute('data-track-label')}_search`;

          Stats.trackEvent(category, 'activate_form_input', { label, property: '', value: '' });
        });
      });

    if (navbar) {
      navbar.addEventListener('click', appendLinkParam);
      navbar.addEventListener('contextmenu', appendLinkParam);
    }
  }
}
