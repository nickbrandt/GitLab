import $ from 'jquery';
import Cookies from 'js-cookie';

import { parseBoolean } from '~/lib/utils/common_utils';

const triggerDocumentEvent = (eventName, eventParam) => {
  $(document).trigger(eventName, eventParam);
};

const bindDocumentEvent = (eventName, callback) => {
  $(document).on(eventName, callback);
};

const toggleContainerClass = className => {
  const containerEl = document.querySelector('.page-with-contextual-sidebar');

  if (containerEl) {
    containerEl.classList.toggle(className);
  }
};

const getCollapsedGutter = () => parseBoolean(Cookies.get('collapsed_gutter'));

const setCollapsedGutter = value => Cookies.set('collapsed_gutter', value);

// This is for mocking methods from this
// file within tests using `spyOnDependency`
// which requires first param to always
// be default export of dependency as per
// https://gitlab.com/help/development/testing_guide/frontend_testing.md#stubbing-and-mocking
const epicUtils = {
  triggerDocumentEvent,
  bindDocumentEvent,
  toggleContainerClass,
  getCollapsedGutter,
  setCollapsedGutter,
};

export default epicUtils;
