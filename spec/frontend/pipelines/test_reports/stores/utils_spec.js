import { formatFilePath, formattedTime } from '~/pipelines/stores/test_reports/utils';

describe('Test reports utils', () => {
  describe('formatFilePath', () => {
    describe('when file string starts with "./"', () => {
      it('should return the file string without the beginning "./"', () => {
        const result = formatFilePath('./test.js');

        expect(result).toBe('test.js');
      });
    });

    describe('when file string starts with "/"', () => {
      it('should return the file string without the beginning "/"', () => {
        const result = formatFilePath('/test.js');

        expect(result).toBe('test.js');
      });
    });

    describe('when file string starts with more than one "/"', () => {
      it('should return the file string without any of the beginning "/"', () => {
        const result = formatFilePath('.//////////////test.js');

        expect(result).toBe('test.js');
      });
    });

    describe('when file string starts without either "." or "/"', () => {
      it('should return the file string without change', () => {
        const result = formatFilePath('test.js');

        expect(result).toBe('test.js');
      });
    });

    describe('when file string contains but does not start with "./"', () => {
      it('should return the file string without change', () => {
        const result = formatFilePath('mock/path./test.js');

        expect(result).toBe('mock/path./test.js');
      });
    });
  });

  describe('formattedTime', () => {
    describe('when time is smaller than a second', () => {
      it('should return time in milliseconds fixed to 2 decimals', () => {
        const result = formattedTime(0.4815162342);
        expect(result).toBe('481.52ms');
      });
    });

    describe('when time is equal to a second', () => {
      it('should return time in seconds fixed to 2 decimals', () => {
        const result = formattedTime(1);
        expect(result).toBe('1.00s');
      });
    });

    describe('when time is greater than a second', () => {
      it('should return time in seconds fixed to 2 decimals', () => {
        const result = formattedTime(4.815162342);
        expect(result).toBe('4.82s');
      });
    });
  });
});
