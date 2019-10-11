import '~/pages/projects/new/index';
import initCustomProjectTemplates from 'ee/projects/custom_project_templates';
import { bindOnboardingEvents } from 'ee/onboarding/new_project';

document.addEventListener('DOMContentLoaded', () => {
  initCustomProjectTemplates();
  bindOnboardingEvents(document.getElementById('new_project'));
});
