import { ALERT_LOCALSTORAGE_KEY } from './constants';

/**
 * Persist alert data to localStorage.
 */
export const persistAlert = ({ title, message, linkUrl, variant } = {}) => {
  const payload = JSON.stringify({ title, message, linkUrl, variant });
  localStorage.setItem(ALERT_LOCALSTORAGE_KEY, payload);
};

/**
 * Return alert data from localStorage.
 */
export const retrieveAlert = () => {
  const initialAlertJSON = window.localStorage.getItem(ALERT_LOCALSTORAGE_KEY);
  // immediately clean up
  window.localStorage.removeItem(ALERT_LOCALSTORAGE_KEY);

  if (!initialAlertJSON) {
    return null;
  }

  return JSON.parse(initialAlertJSON);
};
