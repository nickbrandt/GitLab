import { mount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTable, GlIcon, GlAvatarsInline } from '@gitlab/ui';
import ThroughputTable from 'ee/analytics/merge_request_analytics/components/throughput_table.vue';
import {
  THROUGHPUT_TABLE_STRINGS,
  THROUGHPUT_TABLE_TEST_IDS as TEST_IDS,
} from 'ee/analytics/merge_request_analytics/constants';
import {
  throughputTableData,
  startDate,
  endDate,
  fullPath,
  throughputTableHeaders,
} from '../mock_data';

describe('ThroughputTable', () => {
  let wrapper;

  const createComponent = ({ loading = false, data = {} } = {}) => {
    const $apollo = {
      queries: {
        throughputTableData: {
          loading,
        },
      },
    };

    wrapper = mount(ThroughputTable, {
      mocks: { $apollo },
      provide: {
        fullPath,
      },
      props: {
        startDate,
        endDate,
      },
    });

    wrapper.setData(data);
  };

  const displaysComponent = (component, visible) => {
    expect(wrapper.contains(component)).toBe(visible);
  };

  const additionalData = data => {
    wrapper.setData({
      throughputTableData: [
        {
          ...throughputTableData[0],
          ...data,
        },
      ],
    });
  };

  const findTable = () => wrapper.find(GlTable);

  const findCol = testId => findTable().find(`[data-testid="${testId}"]`);

  const findColSubItem = (colTestId, childTetestId) =>
    findCol(colTestId).find(`[data-testid="${childTetestId}"]`);

  const findColSubComponent = (colTestId, childComponent) =>
    findCol(colTestId).find(childComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays an empty state message when there is no data', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_TABLE_STRINGS.NO_DATA);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('displays a loading icon', () => {
      displaysComponent(GlLoadingIcon, true);
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });

    it('does not display the no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ data: { throughputTableData } });
    });

    it('displays the table', () => {
      displaysComponent(GlTable, true);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('does not display the no data message', () => {
      displaysComponent(GlAlert, false);
    });

    describe('table fields', () => {
      it('displays the correct table headers', () => {
        const headers = findTable().findAll(`[data-testid="${TEST_IDS.TABLE_HEADERS}"]`);

        expect(headers).toHaveLength(throughputTableHeaders.length);

        throughputTableHeaders.forEach((headerText, i) =>
          expect(headers.at(i).text()).toEqual(headerText),
        );
      });

      describe('displays the correct merge request details', () => {
        it('includes the correct title and IID', () => {
          const { title, iid } = throughputTableData[0];

          expect(findCol(TEST_IDS.MERGE_REQUEST_DETAILS).text()).toBe(`${title} !${iid}`);
        });

        it('does not include any icons by default', () => {
          const icon = findColSubComponent(TEST_IDS.MERGE_REQUEST_DETAILS, GlIcon);

          expect(icon.exists()).toBe(false);
        });

        it('includes a label icon and count when available', async () => {
          additionalData({
            labels: {
              nodes: [{ title: 'Brinix' }],
            },
          });

          await wrapper.vm.$nextTick();

          const labelDetails = findColSubItem(
            TEST_IDS.MERGE_REQUEST_DETAILS,
            TEST_IDS.LABEL_DETAILS,
          );
          const icon = labelDetails.find(GlIcon);

          expect(labelDetails.text()).toBe('1');
          expect(icon.exists()).toBe(true);
          expect(icon.props('name')).toBe('label');
        });

        it('includes a pipeline icon and when available', async () => {
          const iconName = 'status_canceled';

          additionalData({
            pipelines: {
              nodes: [
                {
                  detailedStatus: { icon: iconName },
                },
              ],
            },
          });

          await wrapper.vm.$nextTick();

          const icon = findColSubComponent(TEST_IDS.MERGE_REQUEST_DETAILS, GlIcon);

          expect(icon.find(GlIcon).exists()).toBe(true);
          expect(icon.props('name')).toBe(iconName);
        });
      });

      it('displays the correct date merged', () => {
        expect(findCol(TEST_IDS.DATE_MERGED).text()).toBe('2020-08-06');
      });

      it('displays the correct time to merge', () => {
        expect(findCol(TEST_IDS.TIME_TO_MERGE).text()).toBe('4 minutes');
      });

      it('displays the correct milestone', () => {
        expect(findCol(TEST_IDS.MILESTONE).text()).toBe('v1.0');
      });

      it('displays the correct pipeline count', () => {
        expect(findCol(TEST_IDS.PIPELINES).text()).toBe('0');
      });

      it('displays the correctly formatted line changes', () => {
        expect(findCol(TEST_IDS.LINE_CHANGES).text()).toBe('+2 -1');
      });

      it('displays the correct assignees data', () => {
        const assignees = findColSubComponent(TEST_IDS.ASSIGNEES, GlAvatarsInline);

        expect(assignees.exists()).toBe(true);
        expect(assignees.props('avatars')).toBe(throughputTableData[0].assignees.nodes);
      });
    });
  });

  describe('with errors', () => {
    beforeEach(() => {
      createComponent({ data: { hasError: true } });
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('displays an error message', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_TABLE_STRINGS.ERROR_FETCHING_DATA);
    });
  });
});
