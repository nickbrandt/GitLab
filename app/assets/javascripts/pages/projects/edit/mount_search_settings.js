import $ from 'jquery';
import { expandSection, closeSection } from '~/settings_panels';

const mountSearchSettings = async () => {
  if (!gon.features?.searchSettingsInPage) {
    return;
  }

  const { default: initSearch } = await import('~/search_settings');

  initSearch({
    el: document.querySelector('.js-search-settings-app'),
    searchRoot: document.querySelector('#content-body'),
    sectionSelector: 'section.settings',
    onCollapse(section) {
      closeSection($(section));
    },
    onExpand(section) {
      expandSection($(section));
    },
  });
};

export default mountSearchSettings;
