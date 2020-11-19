// shows alert
// shows loader
// shows graph
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { LOAD_FAILURE } from '~/pipelines/constants';
import PipelineGraphWrapper from '~/pipelines/components/graph/graph_component_wrapper.vue';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import getPipelineDetails from '~/pipelines/graphql/queries/get_pipeline_details.query.graphql';
import { mockPipelineResponse } from './mock_data_new';

const defaultProvide = {
  pipelineProjectPath: 'frog/amphibirama',
  pipelineIid: '22',
}

describe('Pipeline graph wrapper', () => {

  const localVue = createLocalVue();
  Vue.use(VueApollo);

  let wrapper;
  const getAlert = () => wrapper.find(GlAlert);
  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const getGraph = () => wrapper.find(PipelineGraph);

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
      [getPipelineDetails, jest.fn().mockResolvedValue(mockPipelineResponse)],
    ];

    const apolloProvider = createMockApollo(requestHandlers);
    createComponent({ apolloProvider, ...options });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when data is loading', () => {

    it('displays the loading icon', () => {
      createComponentWithApollo();
      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('does not display the alert', () => {
      createComponentWithApollo();
      expect(getAlert().exists()).toBe(false);
    });

    it('does not display the graph', () => {
      createComponentWithApollo();
      expect(getGraph().exists()).toBe(false);
    });

  });

  describe('when data has loaded', () => {

    it('does not display the loading icon', async () => {
      createComponentWithApollo();
      await waitForPromises();
      await wrapper.vm.$nextTick();

      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('does not display the alert', async () => {
      createComponentWithApollo();
      await waitForPromises();
      await wrapper.vm.$nextTick();

      console.log('&&&', wrapper.html());
      expect(getAlert().exists()).toBe(false);
    });

    it('displays the graph', async () => {
      createComponentWithApollo();
      await waitForPromises();
      await wrapper.vm.$nextTick();

      expect(getGraph().exists()).toBe(true);
    });

  });


})
