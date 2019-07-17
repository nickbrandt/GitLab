import { mount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'helpers/test_constants';
import CustomMetricsFormFields from 'ee/custom_metrics/components/custom_metrics_form_fields.vue';

describe('custom metrics form fields component', () => {
  let component;
  const getNamedInput = name => component.element.querySelector(`input[name="${name}"]`);
  const validateQueryPath = `${TEST_HOST}/mock/path`;
  const validQueryResponse = { data: { success: true, query: { valid: true, error: '' } } };
  const csrfToken = 'mockToken';
  const formOperation = 'post';
  const debouncedValidateQueryMock = jest.fn();
  const makeFormData = (data = {}) => ({
    formData: {
      title: '',
      yLabel: '',
      query: '',
      unit: '',
      group: '',
      legend: '',
      ...data,
    },
  });
  const mountComponent = props => {
    component = mount(CustomMetricsFormFields, {
      propsData: {
        formOperation,
        validateQueryPath,
        ...props,
      },
      csrfToken,
      sync: false,
      methods: {
        debouncedValidateQuery: debouncedValidateQueryMock,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(axios, 'post').mockResolvedValue(validQueryResponse);
  });

  afterEach(() => {
    axios.post.mockRestore();
    component.destroy();
  });

  it('checks form validity', done => {
    mountComponent({
      metricPersisted: true,
      ...makeFormData({
        title: 'title',
        yLabel: 'yLabel',
        unit: 'unit',
        group: 'group',
      }),
    });

    component.vm.$nextTick(() => {
      expect(component.vm.formIsValid).toBe(true);
      done();
    });
  });

  describe('hidden inputs', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('specifies form operation _method', () => {
      expect(getNamedInput('_method', 'input').value).toBe('post');
    });

    it('specifies authenticity token', () => {
      expect(getNamedInput('authenticity_token', 'input').value).toBe(csrfToken);
    });
  });

  describe('name input', () => {
    const name = 'prometheus_metric[title]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const title = 'mockTitle';
      mountComponent(makeFormData({ title }));

      expect(getNamedInput(name).value).toBe(title);
    });
  });

  describe('group input', () => {
    it('has a default value', () => {
      mountComponent();

      expect(getNamedInput('prometheus_metric[group]', 'glformradiogroup-stub').value).toBe(
        'business',
      );
    });
  });

  describe('query input', () => {
    const name = 'prometheus_metric[query]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives and validates a persisted value', () => {
      const query = 'persistedQuery';
      mountComponent({ metricPersisted: true, ...makeFormData({ query }) });

      expect(axios.post).toHaveBeenCalledWith(validateQueryPath, { query });
      expect(getNamedInput(name).value).toBe(query);
      jest.runAllTimers();
    });

    it('checks validity on user input', () => {
      const query = 'changedQuery';
      mountComponent();
      const queryInput = component.find(`input[name="${name}"]`);
      queryInput.setValue(query);
      queryInput.trigger('input');

      expect(debouncedValidateQueryMock).toHaveBeenCalledWith(query);
    });

    describe('when query is invalid', () => {
      const errorMessage = 'mockErrorMessage';
      const invalidQueryResponse = {
        data: { success: true, query: { valid: false, error: errorMessage } },
      };

      beforeEach(() => {
        axios.post.mockResolvedValue(invalidQueryResponse);
        mountComponent({ metricPersisted: true, ...makeFormData({ query: 'invalidQuery' }) });
      });

      it('sets queryIsValid to false', done => {
        component.vm.$nextTick(() => {
          expect(component.vm.queryIsValid).toBe(false);
          done();
        });
      });

      it('shows invalid query message', () => {
        expect(component.text()).toContain(errorMessage);
      });
    });

    describe('when query is valid', () => {
      beforeEach(() => {
        mountComponent({ metricPersisted: true, ...makeFormData({ query: 'validQuery' }) });
      });

      it('sets queryIsValid to true when query is valid', done => {
        component.vm.$nextTick(() => {
          expect(component.vm.queryIsValid).toBe(true);
          done();
        });
      });

      it('shows valid query message', () => {
        expect(component.text()).toContain('PromQL query is valid');
      });
    });
  });

  describe('yLabel input', () => {
    const name = 'prometheus_metric[y_label]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const yLabel = 'mockYLabel';
      mountComponent(makeFormData({ yLabel }));

      expect(getNamedInput(name).value).toBe(yLabel);
    });
  });

  describe('unit input', () => {
    const name = 'prometheus_metric[unit]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const unit = 'mockUnit';
      mountComponent(makeFormData({ unit }));

      expect(getNamedInput(name).value).toBe(unit);
    });
  });

  describe('legend input', () => {
    const name = 'prometheus_metric[legend]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const legend = 'mockLegend';
      mountComponent(makeFormData({ legend }));

      expect(getNamedInput(name).value).toBe(legend);
    });
  });
});
