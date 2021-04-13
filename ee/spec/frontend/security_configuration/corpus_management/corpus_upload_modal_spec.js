import { GlForm } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import CorpusUploadModal from 'ee/security_configuration/corpus_management/components/corpus_upload_modal.vue';
import { baseResponse, isUploadingResponse , isUploadedResponse } from './mock_data';
import getCorpusesQuery from 'ee/security_configuration/corpus_management/graphql/queries/get_corpuses.query.graphql';

const TEST_PROJECT_FULL_PATH = '/namespace/project';
const TEST_CORPUS_HELP_PATH = '/docs/corpus-management';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Corpus upload modal', () => {
  let wrapper;

  const baseState = jest.fn().mockResolvedValue(baseResponse);
  const isUploadingState = jest.fn().mockResolvedValue(isUploadingResponse);
  const isUploadedState = jest.fn().mockResolvedValue(isUploadedResponse);

  const findCorpusName =   () => wrapper.find('[data-testid="corpus-name"]');
  const findUploadAttatchment =  () => wrapper.find('[data-testid="upload-attatchment-button"]');
  const findUploadCorpus =  () => wrapper.find('[data-testid="upload-corpus"]');
  const findUploadStatus =  () => wrapper.find('[data-testid="upload-status"]');

  function createMockApolloProvider(resolverMock) {
    localVue.use(VueApollo);

    const requestResolvers = [[getCorpusesQuery, resolverMock]];

    return createMockApollo([],requestResolvers);
  }

  const createComponent = (resolverMock, options = {}) => {
    const defaultMocks = {
      $apollo: {
        mutate: jest.fn().mockResolvedValue(baseState)
        },
    }
    

    wrapper = mount(CorpusUploadModal, {
      apolloProvider: createMockApolloProvider(resolverMock),
      //mocks: defaultMocks,
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        corpusHelpPath: TEST_CORPUS_HELP_PATH,
      },
      ...options,
    });
  };


  afterEach(() => {
    wrapper.destroy();
  });

  describe('corpus modal', () => {
    // describe('initial state', () => {
    //   beforeEach(() => {
    //     const data = () => {
    //       return {       
    //         attachmentName: '',
    //         corpusName: '',
    //         files: [],
    //         uploadTimeout: null
    //       }
    //     };

    //     createComponent(baseState,{ data });
    //   });

    //   it('shows empty name field',()=>{
    //     expect(findCorpusName().element.value).toBe('');
    //   });

    //   it('shows the choose file button', () =>{
    //     expect(findUploadAttatchment().exists()).toBe(true);
    //   });

    //   it('show the upload corpus button',()=>{
    //     expect(findUploadCorpus().exists()).toBe(false);
    //   });

    //   it('does not show the upload progress', () =>{
    //     expect(findUploadStatus().exists()).toBe(false);
    //   });
    // });

    // describe('file selected state', () => {
    //   const attachmentName =  'corpus.zip';
    //   const corpusName = 'User entered name';

    //   beforeEach(() => {
    //     const data = () => {
    //       return {       
    //         attachmentName,
    //         corpusName,
    //         files: [attachmentName],
    //         uploadTimeout: null
    //       }
    //     };

    //     createComponent(baseState,{ data });
    //   });

    //   it('shows name field',()=>{
    //     expect(findCorpusName().element.value).toBe(corpusName);
    //   });

    //   it('shows the choose file button', () =>{
    //     expect(findUploadAttatchment().exists()).toBe(true);
    //   });

    //   it('shows the upload corpus button',()=>{
    //     expect(findUploadCorpus().exists()).toBe(true);
    //   });

    //   it('does not show the upload progress', () =>{
    //     expect(findUploadStatus().exists()).toBe(false);
    //   });
    // });
    
    describe('uploading state', () => {
      const attachmentName =  'corpus.zip';
      const corpusName = 'User entered name';

      beforeEach(() => {
        const data = () => {
          return {       
            attachmentName,
            corpusName,
            files: [attachmentName],
            uploadTimeout: null
          }
        };

        createComponent(isUploadingState,{ data });
      });

      it('shows name field',()=>{
        expect(findCorpusName().element.value).toBe(corpusName);
      });

      it('shows the choose file button', () =>{
        expect(findUploadAttatchment().exists()).toBe(false);
      });

      it('shows the upload corpus button',()=>{
        expect(findUploadCorpus().exists()).toBe(false);
      });

      it('does not show the upload progress', () =>{
        expect(findUploadStatus().exists()).toBe(true);
      });
    });
    
    // describe('file uploaded state', () => {
    //   beforeEach(() => {
    //     const data = () => {
    //       return { states: { mockedPackages: { totalSize: 12 } } };
    //     };

    //     createComponent({ data });
    //   });
    // });      


  });
});
