import Api from '~/api';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineBranchNameToken from '~/pipelines/components/tokens/pipeline_branch_name_token.vue';
import { branches, mockBranchesAfterMap } from '../mock_data';

describe('Pipeline Branch Name Token', () => {
  let wrapper;
  let mock;

  const findFilteredSearchToken = () => wrapper.find(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () => wrapper.findAll(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const defaultProps = {
    config: {
      type: 'ref',
      icon: 'branch',
      title: 'Branch name',
      dataType: 'ref',
      unique: true,
      branches,
      projectId: '21',
    },
    value: {
      data: '',
    },
  };

  const createComponent = (options, data) => {
    wrapper = shallowMount(PipelineBranchNameToken, {
      propsData: {
        ...defaultProps,
      },
      data() {
        return {
          ...data,
        };
      },
      ...options,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    jest.spyOn(Api, 'branches').mockResolvedValue({ data: branches });

    createComponent();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  it('fetches and sets project branches', () => {
    expect(Api.branches).toHaveBeenCalled();

    expect(wrapper.vm.branches).toEqual(mockBranchesAfterMap);
  });

  describe('displays loading icon correctly', () => {
    it('shows loading icon', () => {
      createComponent({ stubs }, { loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent({ stubs }, { loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('shows branches correctly', () => {
    it('renders all trigger authors', () => {
      createComponent({ stubs }, { branches, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(branches.length);
    });

    it('renders only the branch searched for', () => {
      const mockBranches = ['master'];
      createComponent({ stubs }, { branches: mockBranches, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(mockBranches.length);
    });
  });
});
