import { createLocalVue, shallowMount } from '@vue/test-utils';
import MergeRequestTableRow from 'ee/analytics/productivity_analytics/components/mr_table_row.vue';
import { GlAvatar } from '@gitlab/ui';
import mockMergeRequests from './../mock_data';

describe('MergeRequestTableRow component', () => {
  let wrapper;

  const defaultProps = {
    mergeRequest: mockMergeRequests[0],
    metricType: 'time_to_last_commit',
    metricLabel: 'Time from first comment to last commit',
  };

  const factory = (props = defaultProps) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(MergeRequestTableRow), {
      localVue,
      sync: false,
      propsData: { ...props },
    });
  };

  const findMrDetails = () => wrapper.find('.qa-mr-details');
  const findMrMetrics = () => wrapper.find('.qa-mr-metrics');
  const findMetricColumns = () => findMrMetrics().findAll('.metric-col');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('template', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the avatar with correct URL', () => {
      const avatar = wrapper.find(GlAvatar);

      expect(avatar.exists()).toBe(true);
      expect(avatar.props('src')).toEqual(defaultProps.mergeRequest.author_avatar_url);
    });

    it('renders the merge request title', () => {
      const title = findMrDetails().find('.mr-title');

      expect(title.exists()).toBe(true);
      expect(title.text()).toContain(defaultProps.mergeRequest.title);
    });

    describe('metric columns', () => {
      it('renders two metric columns', () => {
        expect(findMetricColumns().length).toBe(2);
      });

      it('renders the "Time to merge" metric column', () => {
        expect(
          findMetricColumns()
            .at(0)
            .text(),
        ).toContain(defaultProps.mergeRequest.time_to_merge);
      });
    });
  });

  describe('computed', () => {
    describe('mrId', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the merge request ID with a leading "!"', () => {
        expect(wrapper.vm.mrId).toBe(`!${defaultProps.mergeRequest.iid}`);
      });
    });

    describe('commitCount', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the number of commits', () => {
        expect(wrapper.vm.commitCount).toBe(`${defaultProps.mergeRequest.commits_count} commit`);
      });
    });

    describe('locPerCommit', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the LOC per commit', () => {
        expect(wrapper.vm.locPerCommit).toBe(
          `${defaultProps.mergeRequest.loc_per_commit} LOC/commit`,
        );
      });
    });

    describe('filesTouched', () => {
      beforeEach(() => {
        factory();
      });

      it('returns the number of files touched', () => {
        expect(wrapper.vm.filesTouched).toBe(
          `${defaultProps.mergeRequest.files_touched} files touched`,
        );
      });
    });

    describe('selectedMetric', () => {
      beforeEach(() => {
        factory();
      });

      it("returns the selected metric's key", () => {
        expect(wrapper.vm.selectedMetric).toBe(defaultProps.mergeRequest[defaultProps.metricType]);
      });
    });

    describe('metricTimeUnit', () => {
      describe('when metricType is "days_to_merge"', () => {
        beforeEach(() => {
          factory({
            ...defaultProps,
            metricType: 'days_to_merge',
          });
        });

        it('returns "days"', () => {
          expect(wrapper.vm.metricTimeUnit).toBe('days');
        });
      });

      describe('when metricType is not "days_to_merge"', () => {
        beforeEach(() => {
          factory({
            ...defaultProps,
            metricType: 'time_to_last_commit',
          });
        });

        it('returns "hrs"', () => {
          expect(wrapper.vm.metricTimeUnit).toBe('hrs');
        });
      });
    });
  });
});
