import sanitize from 'sanitize-html';

export const parseIssuableData = () => {
  try {
    const initialDataEl = document.getElementById('js-issuable-app-initial-data');

    return JSON.parse(sanitize(initialDataEl.textContent).replace(/&quot;/g, '"'));
  } catch (e) {
    return {};
  }
};

export default {};
