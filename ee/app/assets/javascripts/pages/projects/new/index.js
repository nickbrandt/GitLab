import '~/pages/projects/new/index';
import initCustomProjectTemplates from 'ee/projects/custom_project_templates';
import Tracking from '~/tracking';
import { bindOnboardingEvents } from 'ee/onboarding/new_project';

document.addEventListener('DOMContentLoaded', () => {
  initCustomProjectTemplates();
  new Tracking().bind();
  bindOnboardingEvents(document.getElementById('new_project'));
});
