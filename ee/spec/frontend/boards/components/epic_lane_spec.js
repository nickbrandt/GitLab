import Vue from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { shallowMount } from '@vue/test-utils';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import IssuesLaneList from 'ee/boards/components/issues_lane_list.vue';
import { GlIcon } from '@gitlab/ui';
import { mockEpic, mockLists, mockIssues } from '../mock_data';
import List from '~/boards/models/list';
import { TEST_HOST } from 'helpers/test_constants';

describe('EpicLane', () => {
  let wrapper;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(`${TEST_HOST}/lists/1/issues`).reply(200, { issues: mockIssues });
  });

  const createComponent = (props = {}) => {
    const defaultProps = {
      epic: mockEpic,
      lists: mockLists.map(listMock => Vue.observable(new List(listMock))),
    };

    wrapper = shallowMount(EpicLane, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('icon aria label is Opened when epic is opened', () => {
      expect(wrapper.find(GlIcon).attributes('aria-label')).toEqual('Opened');
    });

    it('icon aria label is Closed when epic is closed', () => {
      createComponent({ epic: { ...mockEpic, state: 'closed' } });
      expect(wrapper.find(GlIcon).attributes('aria-label')).toEqual('Closed');
    });

    it('displays total count of issues in epic', () => {
      expect(wrapper.find('[data-testid="epic-lane-issue-count"]').text()).toContain(5);
    });

    it('displays 2 icons', () => {
      expect(wrapper.findAll(GlIcon)).toHaveLength(2);
    });

    it('displays epic title', () => {
      expect(wrapper.text()).toContain(mockEpic.title);
    });

    it('renders one IssuesLaneList component per list passed in props', () => {
      expect(wrapper.findAll(IssuesLaneList)).toHaveLength(wrapper.props('lists').length);
    });
  });
});
