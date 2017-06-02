function expandSection($section) {
  $section.find('.js-settings-toggle').text('Close');
  $section.find('.settings-content').removeClass('no-animate').addClass('expanded').off('scroll');
}

function closeSection($section) {
  $section.find('.js-settings-toggle').text('Expand');
  $section.find('.settings-content').removeClass('expanded').on('scroll', () => expandSection($section));
}

function toggleSection($section) {
  if ($section.find('.settings-content').hasClass('expanded')) {
    closeSection($section);
  } else {
    expandSection($section);
  }
}

export default function initSettingsPanels() {
  $('.settings').each((i, elm) => {
    const $section = $(elm);
    $section.on('click', '.js-settings-toggle', () => toggleSection($section));
    closeSection($section);
  });
}
