import FilteredSearchServiceDesk from './filtered_search';
import initIssuablesList from '~/issuables_list';

initIssuablesList();

document.addEventListener('DOMContentLoaded', () => {
  const supportBotData = JSON.parse(
    document.querySelector('.js-service-desk-issues').dataset.supportBot,
  );

  const filteredSearchManager = new FilteredSearchServiceDesk(supportBotData);

  filteredSearchManager.setup();
});
