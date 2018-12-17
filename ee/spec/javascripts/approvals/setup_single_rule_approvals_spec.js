import $ from 'jquery';
import setup from 'ee/approvals/setup_single_rule_approvals';

describe('EE setup_single_rule_approvals', () => {
  preloadFixtures('merge_requests_ee/merge_request_edit.html.raw');

  let $approversEl;
  let $suggestionEl;

  beforeEach(() => {
    loadFixtures('merge_requests_ee/merge_request_edit.html.raw');
    $approversEl = $('ul.approver-list');
    $suggestionEl = $('.suggested-approvers');
    setup();
  });

  describe('add suggested approver', () => {
    it('should add approver when suggested user is clicked', () => {
      expect($approversEl.find('li.approver').length).toEqual(0);

      $suggestionEl
        .find('a')
        .first()
        .click();

      $suggestionEl
        .find('a')
        .last()
        .click();

      expect($approversEl.find('li.approver').length).toEqual(2);
    });

    it('only adds approver once when the same suggested user is clicked multiple times', () => {
      expect($approversEl.find('li.approver').length).toEqual(0);

      $suggestionEl
        .find('a')
        .first()
        .click();

      $suggestionEl
        .find('a')
        .first()
        .click();

      expect($approversEl.find('li.approver').length).toEqual(1);
    });
  });

  describe('remove unsaved approver', () => {
    beforeEach(() => {
      $suggestionEl.find('a').click(); // Adds two approvers
    });

    it('should remove approver if confirm window result is positive', () => {
      spyOn(window, 'confirm').and.returnValue(true);

      $approversEl
        .find('.unsaved-approvers.approver a.btn-remove')
        .first()
        .click();

      expect($approversEl.find('li.approver').length).toEqual(1);
    });

    it('should not remove approver if confirm window result is negative', () => {
      spyOn(window, 'confirm').and.returnValue(false);

      $approversEl
        .find('.unsaved-approvers.approver a.btn-remove')
        .first()
        .click();

      expect($approversEl.find('li.approver').length).toEqual(2);
    });
  });

  describe('remove unsaved approver group', () => {
    it('should remove approver group if confirm window result is positive', () => {
      spyOn(window, 'confirm').and.returnValue(true);

      expect($approversEl.find('li.approver-group').length).toEqual(1);

      $approversEl
        .find('.unsaved-approvers.approver-group a.btn-remove')
        .first()
        .click();

      expect($approversEl.find('li.approver-group').length).toEqual(0);
    });

    it('should not remove approver group if confirm window result is negative', () => {
      spyOn(window, 'confirm').and.returnValue(false);

      expect($approversEl.find('li.approver-group').length).toEqual(1);

      $approversEl
        .find('.unsaved-approvers.approver-group a.btn-remove')
        .first()
        .click();

      expect($approversEl.find('li.approver-group').length).toEqual(1);
    });
  });
});
