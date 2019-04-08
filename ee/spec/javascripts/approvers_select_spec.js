import ApproversSelect from 'ee/approvers_select';

describe('ApproversSelect', () => {
  describe('saveApproversComplete', () => {
    let $input;
    let $approverSelect;
    let $loadWrapper;

    beforeEach(() => {
      $input = {
        val: jasmine.createSpy(),
      };

      $approverSelect = {
        select2: jasmine.createSpy().and.callFake(function() {
          return this;
        }),
        trigger: jasmine.createSpy(),
      };

      $loadWrapper = {
        addClass: jasmine.createSpy(),
      };

      ApproversSelect.saveApproversComplete($input, $approverSelect, $loadWrapper);
    });

    it('should empty the $input value', () => {
      expect($input.val).toHaveBeenCalledWith('');
    });

    it('should empty the select2 value and trigger a change event', () => {
      expect($approverSelect.select2).toHaveBeenCalledWith('val', '');
      expect($approverSelect.trigger).toHaveBeenCalledWith('change');
    });

    it('should hide loadWrapper', () => {
      expect($loadWrapper.addClass).toHaveBeenCalledWith('hidden');
    });
  });

  describe('formatResult', () => {
    it('escapes name', () => {
      const output = ApproversSelect.formatResult({
        name: '<script>alert("testing")</script>',
        username: 'testing',
        avatar_url: gl.TEST_HOST,
        full_name: '<script>alert("testing")</script>',
        full_path: 'testing',
      });

      expect(output).not.toContain('<script>alert("testing")</script>');
    });

    it('escapes full name', () => {
      const output = ApproversSelect.formatResult({
        username: 'testing',
        avatar_url: gl.TEST_HOST,
        full_name: '<script>alert("testing")</script>',
        full_path: 'testing',
      });

      expect(output).not.toContain('<script>alert("testing")</script>');
    });
  });

  describe('formatSelection', () => {
    it('escapes full name', () => {
      expect(
        ApproversSelect.formatSelection({
          full_name: '<script>alert("testing")</script>',
        }),
      ).not.toBe('<script>alert("testing")</script>');
    });

    it('escapes name', () => {
      expect(
        ApproversSelect.formatSelection({
          name: '<script>alert("testing")</script>',
        }),
      ).not.toBe('<script>alert("testing")</script>');
    });
  });
});
