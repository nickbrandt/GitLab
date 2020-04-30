import { mount } from '@vue/test-utils';
import PipelinesTable from '~/pipelines/components/pipelines_table.vue';

describe('Pipelines Table', () => {
  let pipeline;
  let wrapper;

  const jsonFixtureName = 'pipelines/pipelines.json';

  const defaultProps = {
    pipelines: [],
    autoDevopsHelpPath: 'foo',
    viewType: 'root',
  };

  const createComponent = (props = defaultProps) => {
    wrapper = mount(PipelinesTable, {
      propsData: props,
    });
  };

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);
    pipeline = pipelines.find(p => p.user !== null && p.commit !== null);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('table', () => {
    it('should render a table', () => {
      expect(wrapper.classes()).toContain('ci-table');
    });

    it('should render table head with correct columns', () => {
      expect(wrapper.find('.table-section.js-pipeline-status').text()).toEqual('Status');

      expect(wrapper.find('.table-section.js-pipeline-info').text()).toEqual('Pipeline');

      expect(wrapper.find('.table-section.js-pipeline-commit').text()).toEqual('Commit');

      expect(wrapper.find('.table-section.js-pipeline-stages').text()).toEqual('Stages');
    });
  });

  describe('without data', () => {
    it('should render an empty table', () => {
      expect(wrapper.find('.commit.gl-responsive-table-row').exists()).toBe(false);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      createComponent({ pipelines: [pipeline], autoDevopsHelpPath: 'foo', viewType: 'root' });

      expect(wrapper.findAll('.commit.gl-responsive-table-row')).toHaveLength(1);
    });
  });
});
