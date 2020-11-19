// shows alert
// shows loader
// shows graph
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import { LOAD_FAILURE } from '~/pipelines/constants';
import PipelineGraphWrapper from '~/pipelines/components/graph/graph_component_wrapper.vue';
import getPipelineDetails from '~/pipelines/graphql/queries/get_pipeline_details.query.graphql';


const defaultProvide = {
  pipelineProjectPath: 'frog/amphibirama',
  pipelineIid: '33',
}

const createMockApolloProvider = () => createMockApollo();

describe('Pipeline graph wrapper', () => {

  const localVue = createLocalVue();
  Vue.use(VueApollo);

  let wrapper;
  const getAlert = () => wrapper.find(GlAlert);
  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const createComponent = ({
    apolloProvider,
    data = {},
    provide = defaultProvide,
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(PipelineGraphWrapper, {
      localVue,
      provide,
      apolloProvider,
      data() {
        return {
          ...data
        }
      }
    })
  };

  const createComponentWithApollo = (options = {}) => {
    const requestHandlers = [
      [getPipelineDetails, jest.fn().mockResolvedValue({})],
    ];

    const apolloProvider = createMockApollo(requestHandlers);
    createComponent({ apolloProvider, ...options });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when data is loading', () => {
    beforeEach(() => {
      // createComponentWithApollo();
    });

    it('displays the loading icon', () => {
      createComponentWithApollo();
      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('does not display the alert', async() => {
      createComponentWithApollo();
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
      expect(getAlert().exists()).toBe(false);
    });



  });


})
