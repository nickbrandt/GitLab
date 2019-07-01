import { bindOnboardingEvents, getProjectPath } from 'ee/onboarding/new_project';
import onboardingUtils from 'ee/onboarding/utils';
import { AVAILABLE_TOURS } from 'ee/onboarding/constants';
import { TEST_HOST } from 'helpers/test_constants';
import { setHTMLFixture } from 'helpers/fixtures';

describe('User onboarding new project utils', () => {
  describe('getProjectPath', () => {
    describe('when there exists a namespace select', () => {
      beforeEach(() => {
        setHTMLFixture(`
          <div class='active tab-pane js-toggle-container'>
            <input id="project_path" value="my-project"/>
            <select class="js-select-namespace">
              <option data-show-path="${TEST_HOST}/MyPath" selected="selected">MyPath</option>
              <option data-show-path="${TEST_HOST}/foobar">foobar</option>
            </select>
          </div>
        `);
      });

      it('returns the namespace and path', () => {
        const result = getProjectPath();

        expect(result).toEqual(`${TEST_HOST}/MyPath/my-project`);
      });
    });

    describe("when there doesn't exist a namespace select", () => {
      beforeEach(() => {
        setHTMLFixture(`
          <div class='active tab-pane js-toggle-container'>
            <input id="project_path" value="my-project"/>
          </div>
        `);
      });

      it('returns the path only if there is no namespace select', () => {
        const result = getProjectPath();

        expect(result).toEqual('my-project');
      });
    });
  });

  describe('bindOnboardingEvents', () => {
    let form;
    let submitBtn;
    let submitSpy;

    beforeEach(() => {
      setHTMLFixture(`
        <div class='active tab-pane js-toggle-container'>
          <form id="new_project">
            <input id="project_path" value="my-project"/>
            <input id="submitBtn" type="submit" value="Create project">
          </form>
        </div>
      `);

      submitSpy = jest
        .fn()
        .mockName('submit')
        .mockImplementation(event => event.preventDefault());

      form = document.getElementById('new_project');
      submitBtn = document.getElementById('submitBtn');
      form.addEventListener('submit', submitSpy);
      jest.spyOn(form, 'submit').mockImplementation(() => {});
    });

    describe('when onboarding is not dismissed and there is an onboarding state on the local storage', () => {
      beforeEach(() => {
        jest.spyOn(onboardingUtils, 'isOnboardingDismissed').mockReturnValue(false);
        jest.spyOn(onboardingUtils, 'getOnboardingLocalStorageState').mockReturnValue({
          tourKey: AVAILABLE_TOURS.CREATE_PROJECT_TOUR,
        });
      });

      it('adds the submit event listener to the form', () => {
        jest.spyOn(form, 'addEventListener');

        bindOnboardingEvents(form);

        expect(form.addEventListener).toHaveBeenCalledWith('submit', jasmine.any(Function));
      });

      it('calls updateLocalStorage with the correct project path when the form is submitted', () => {
        jest.spyOn(onboardingUtils, 'updateLocalStorage');

        bindOnboardingEvents(form);

        submitBtn.click();

        expect(onboardingUtils.updateLocalStorage).toHaveBeenCalledWith({
          createdProjectPath: 'my-project',
        });
      });
    });

    describe('when onboarding is dismissed', () => {
      beforeEach(() => {
        jest.spyOn(onboardingUtils, 'isOnboardingDismissed').mockReturnValue(true);
      });

      it('does not add the submit event listener to the form', () => {
        jest.spyOn(form, 'addEventListener');

        bindOnboardingEvents(form);

        expect(form.addEventListener).not.toHaveBeenCalled();
      });

      it('does not call updateLocalStorage when the form is submitted', () => {
        jest.spyOn(onboardingUtils, 'updateLocalStorage');

        bindOnboardingEvents(form);

        submitBtn.click();

        expect(onboardingUtils.updateLocalStorage).not.toHaveBeenCalled();
      });
    });

    describe('when the user is currently on a tour part different from the "Create Project Tour"', () => {
      beforeEach(() => {
        jest.spyOn(onboardingUtils, 'isOnboardingDismissed').mockReturnValue(false);
        jest.spyOn(onboardingUtils, 'getOnboardingLocalStorageState').mockReturnValue({
          tourKey: AVAILABLE_TOURS.GITLAB_GUIDED_TOUR,
        });
      });

      it('does not add the submit event listener to the form', () => {
        jest.spyOn(form, 'addEventListener');

        bindOnboardingEvents(form);

        expect(form.addEventListener).not.toHaveBeenCalled();
      });

      it('does not call updateLocalStorage when the form is submitted', () => {
        jest.spyOn(onboardingUtils, 'updateLocalStorage');

        bindOnboardingEvents(form);

        submitBtn.click();

        expect(onboardingUtils.updateLocalStorage).not.toHaveBeenCalled();
      });
    });
  });
});
