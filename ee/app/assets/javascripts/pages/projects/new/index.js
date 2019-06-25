import '~/pages/projects/new/index';
import initCustomProjectTemplates from 'ee/projects/custom_project_templates';
import bindTrackEvents from 'ee/projects/track_project_new';
import { bindOnboardingEvents } from 'ee/onboarding/new_project';

document.addEventListener('DOMContentLoaded', () => {
  initCustomProjectTemplates();
  bindTrackEvents('.js-toggle-container');
  bindOnboardingEvents(document.getElementById('new_project'));
});
