import $ from 'jquery';

const triggerDocumentEvent = (eventName, eventParam) => {
  $(document).trigger(eventName, eventParam);
};

const bindDocumentEvent = (eventName, callback) => {
  $(document).on(eventName, callback);
};

// This is for mocking methods from this
// file within tests using `spyOnDependency`
// which requires first param to always
// be default export of dependency as per
// https://gitlab.com/help/development/testing_guide/frontend_testing.md#stubbing-and-mocking
const epicUtils = {
  triggerDocumentEvent,
  bindDocumentEvent,
};

export default epicUtils;
