import onboardingUtils from './utils';
import { AVAILABLE_TOURS } from './constants';

export const getProjectPath = () => {
  let projectPath;
  const activeTab = document.querySelector('.js-toggle-container.active');
  const projectPathInput = activeTab.querySelector('#project_path');
  const select = activeTab.querySelector('select.js-select-namespace');

  if (select) {
    const selectedOption = select.options[select.selectedIndex];
    const { showPath } = selectedOption.dataset;
    projectPath = `${showPath}/${projectPathInput.value}`;
  } else {
    projectPath = projectPathInput.value;
  }

  return projectPath;
};

/**
 * Binds a submit event handler to the form on the "New project" page (for user onboarding only).
 * It intercepts form submit and sets the project path of project to be created on the localStorage.
 * The project path is used later in the onboarding process.
 *
 * @param {*} form The form we're going to add the submit event handler to
 */
export const bindOnboardingEvents = form => {
  if (!form) {
    return;
  }

  const onboardingState = onboardingUtils.getOnboardingLocalStorageState();

  if (
    !onboardingUtils.isOnboardingDismissed() &&
    onboardingState &&
    onboardingState.tourKey === AVAILABLE_TOURS.CREATE_PROJECT_TOUR
  ) {
    form.addEventListener('submit', event => {
      event.preventDefault();
      event.stopPropagation();

      const createdProjectPath = getProjectPath();

      onboardingUtils.updateLocalStorage({ createdProjectPath });

      form.submit();
    });
  }
};
