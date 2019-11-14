import { shallowMount } from '@vue/test-utils';
import PackageInformation from 'ee/packages/details/components/information.vue';

describe('PackageInformation', () => {
  let wrapper;

  const defaultProps = {
    information: [
      {
        label: 'Information one',
        value: 'Information value one',
      },
      {
        label: 'Information two',
        value: 'Information value two',
      },
      {
        label: 'Information three',
        value: 'Information value three',
      },
    ],
  };

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = shallowMount(PackageInformation, {
      propsData,
    });
  }

  const headingSelector = () => wrapper.find('.card-header > strong');
  const informationSelector = () => wrapper.findAll('ul.content-list li');
  const informationRowText = index =>
    informationSelector()
      .at(index)
      .text();

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('renders the information block with default heading', () => {
    createComponent();

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe('Package information');
  });

  it('renders a custom supplied heading', () => {
    const heading = 'A custom heading';

    createComponent({
      heading,
    });

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe(heading);
  });

  it('renders the supplied information', () => {
    createComponent();

    expect(informationSelector().length).toBe(3);
    expect(informationRowText(0)).toContain('one');
    expect(informationRowText(1)).toContain('two');
    expect(informationRowText(2)).toContain('three');
  });
});
