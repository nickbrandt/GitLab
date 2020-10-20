import Vue from 'vue';
import createComponent from 'helpers/vue_mount_component_helper';
import upload from '~/ide/components/new_dropdown/upload.vue';

describe('new dropdown upload', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(upload);

    vm = createComponent(Component, {
      path: '',
    });

    vm.entryName = 'testing';

    jest.spyOn(vm, '$emit');
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('openFile', () => {
    it('calls for each file', () => {
      const files = ['test', 'test2', 'test3'];

      jest.spyOn(vm, 'readFile').mockImplementation(() => {});
      jest.spyOn(vm.$refs.fileUpload, 'files', 'get').mockReturnValue(files);

      vm.openFile();

      expect(vm.readFile.mock.calls.length).toBe(3);

      files.forEach((file, i) => {
        expect(vm.readFile.mock.calls[i]).toEqual([file]);
      });
    });
  });

  describe('readFile', () => {
    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsBinaryString').mockImplementation(() => {});
    });

    it('calls readAsBinaryString for all files', () => {
      const file = {
        type: 'images/png',
      };

      vm.readFile(file);

      expect(FileReader.prototype.readAsBinaryString).toHaveBeenCalledWith(file);
    });
  });

  describe('createFile', () => {
    const textTarget = {
      result: 'plain text',
    };
    const binaryTarget = {
      result: '😺',
    };

    const textFile = new File(['plain text'], 'textFile');
    const binaryFile = new File(['😺'], 'binaryFile');

    beforeEach(() => {
      jest.spyOn(FileReader.prototype, 'readAsText');
    });

    it('calls readAsText and creates file in plain text (without encoding) if the file content is plain text', done => {
      const waitForCreate = new Promise(resolve => vm.$on('create', resolve));

      vm.createFile(textTarget, textFile);

      expect(FileReader.prototype.readAsText).toHaveBeenCalledWith(textFile);

      waitForCreate
        .then(() => {
          expect(vm.$emit).toHaveBeenCalledWith('create', {
            name: textFile.name,
            type: 'blob',
            content: 'plain text',
            rawPath: '',
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('creates a blob URL for the content if binary', () => {
      vm.createFile(binaryTarget, binaryFile);

      expect(FileReader.prototype.readAsText).not.toHaveBeenCalled();

      expect(vm.$emit).toHaveBeenCalledWith('create', {
        name: binaryFile.name,
        type: 'blob',
        content: '😺',
        rawPath: 'blob:https://gitlab.com/048c7ac1-98de-4a37-ab1b-0206d0ea7e1b',
      });
    });
  });
});
