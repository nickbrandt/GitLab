export const WARNING = 'warning';
export const DANGER = 'danger';

export const WARNING_ALERT_CLASS = 'warning_message';
export const DANGER_ALERT_CLASS = 'danger_message';

export const WARNING_TEXT_CLASS = 'text-warning-900';
export const DANGER_TEXT_CLASS = 'text-danger-900';

// Limit the number of vulnerabilities to display so as to avoid jank.
// In practice, this limit will probably never be reached, since the
// largest number of vulnerabilities we've seen one dependency have is 20.
export const MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY = 50;
