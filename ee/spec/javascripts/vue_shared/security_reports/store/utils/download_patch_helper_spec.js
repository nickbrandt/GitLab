import downloadPatchHelper from 'ee/vue_shared/security_reports/store/utils/download_patch_helper';

describe('downloadPatchHelper', () => {
  beforeAll(() => {
    spyOn(document, 'createElement').and.callThrough();
    spyOn(document.body, 'appendChild').and.callThrough();
    spyOn(document.body, 'removeChild').and.callThrough();
  });

  afterEach(() => {
    document.createElement.calls.reset();
    document.body.appendChild.calls.reset();
    document.body.removeChild.calls.reset();
  });

  describe('with a base64 encoded string', () => {
    it('creates a download link and clicks on it to download the file', done => {
      const base64String = btoa('abcdef');

      document.onclick = e => {
        expect(e.target.download).toBe('remediation.patch');
        expect(e.target.href).toBe('data:text/plain;base64,YWJjZGVm');
        done();
      };

      downloadPatchHelper(base64String);

      expect(document.createElement).toHaveBeenCalledTimes(1);
      expect(document.body.appendChild).toHaveBeenCalledTimes(1);
      expect(document.body.removeChild).toHaveBeenCalledTimes(1);
    });
  });

  describe('without a base64 encoded string', () => {
    it('creates a download link and clicks on it to download the file', done => {
      const unencodedString = 'abcdef';

      document.onclick = e => {
        expect(e.target.download).toBe('remediation.patch');
        expect(e.target.href).toBe('data:text/plain;base64,YWJjZGVm');
        done();
      };

      downloadPatchHelper(unencodedString, { isEncoded: false });

      expect(document.createElement).toHaveBeenCalledTimes(1);
      expect(document.body.appendChild).toHaveBeenCalledTimes(1);
      expect(document.body.removeChild).toHaveBeenCalledTimes(1);
    });
  });
});
