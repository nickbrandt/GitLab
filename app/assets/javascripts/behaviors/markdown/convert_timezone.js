/**
 * Highlights the current user in existing elements with a user ID data attribute.
 *
 * @param elements DOM elements that represent user mentions
 */
export default function convertTimezone(elements) {
  const currentTimezone = gon && gon.timezone;
  if (!currentTimezone) {
    return;
  }

  elements.forEach(element => {
    element.textContent = new Date(element.dataset.timezone).toLocaleString("en-US", {timeZone: gon.timezone});
  });
}
