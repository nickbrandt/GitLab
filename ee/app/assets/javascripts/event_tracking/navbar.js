import Stats from 'ee/stats';

export default function trackNavbarEvents() {
  const container = '.navbar-gitlab';
  const category = 'navbar_top';

  Stats.bindTrackableContainer(container, category);

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
}
