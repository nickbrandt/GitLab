import downloadPatchHelper from 'ee/vue_shared/security_reports/store/utils/download_patch_helper';

describe('downloadPatchHelper', () => {
  beforeEach(() => {
    jest.spyOn(document, 'createElement');
    jest.spyOn(document.body, 'appendChild');
    jest.spyOn(document.body, 'removeChild');
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

      expect(document.createElement).toHaveBeenCalledWith('a');
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

      expect(document.createElement).toHaveBeenCalledWith('a');
      expect(document.body.appendChild).toHaveBeenCalledTimes(1);
      expect(document.body.removeChild).toHaveBeenCalledTimes(1);
    });
  });
});
