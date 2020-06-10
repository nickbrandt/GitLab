import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import VulnerabilityDetails from 'ee/vulnerabilities/components/details.vue';

describe('Vulnerability Details', () => {
  let wrapper;

  const vulnerability = {
    title: 'some title',
    severity: 'bad severity',
    confidence: 'high confidence',
    report_type: 'nice report_type',
  };

  const finding = {
    description: 'finding description',
  };

  const createWrapper = findingOverrides => {
    const propsData = {
      vulnerability,
      finding: { ...finding, ...findingOverrides },
    };

    wrapper = mount(VulnerabilityDetails, { propsData });
  };

  const getById = id => wrapper.find(`[data-testid="${id}"]`);
  const getAllById = id => wrapper.findAll(`[data-testid="${id}"]`);
  const getText = id => getById(id).text();

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the properties that should always be shown', () => {
    createWrapper();
    expect(getText('title')).toBe(vulnerability.title);
    expect(getText('description')).toBe(finding.description);
    expect(wrapper.find(SeverityBadge).props('severity')).toBe(vulnerability.severity);
    expect(getText('confidence')).toBe(`Confidence: ${vulnerability.confidence}`);
    expect(getText('reportType')).toBe(`Report Type: ${vulnerability.report_type}`);

    expect(getById('image').exists()).toBeFalsy();
    expect(getById('os').exists()).toBeFalsy();
    expect(getById('file').exists()).toBeFalsy();
    expect(getById('class').exists()).toBeFalsy();
    expect(getById('method').exists()).toBeFalsy();
    expect(getAllById('link')).toHaveLength(0);
    expect(getAllById('identifier')).toHaveLength(0);
  });

  it('shows the location image if it exists', () => {
    createWrapper({ location: { image: 'some image' } });
    expect(getText('image')).toBe(`Image: some image`);
  });

  it('shows the operating system if it exists', () => {
    createWrapper({ location: { operating_system: 'linux' } });
    expect(getText('namespace')).toBe(`Namespace: linux`);
  });

  it('shows the finding class if it exists', () => {
    createWrapper({ location: { file: 'file', class: 'class name' } });
    expect(getText('class')).toBe(`Class: class name`);
  });

  it('shows the finding method if it exists', () => {
    createWrapper({ location: { file: 'file', method: 'method name' } });
    expect(getText('method')).toBe(`Method: method name`);
  });

  it('shows the links if they exist', () => {
    createWrapper({ links: [{ url: '0' }, { url: '1' }, { url: '2' }] });
    const links = getAllById('link');
    expect(links).toHaveLength(3);

    links.wrappers.forEach((link, index) => {
      expect(link.attributes('target')).toBe('_blank');
      expect(link.attributes('href')).toBe(index.toString());
      expect(link.text()).toBe(index.toString());
    });
  });

  it('shows the finding identifiers if they exist', () => {
    createWrapper({
      identifiers: [{ url: '0', name: '00' }, { url: '1', name: '11' }, { url: '2', name: '22' }],
    });

    const identifiers = getAllById('identifier');
    expect(identifiers).toHaveLength(3);

    const checkIdentifier = index => {
      const identifier = identifiers.at(index);
      expect(identifier.attributes('target')).toBe('_blank');
      expect(identifier.attributes('href')).toBe(index.toString());
      expect(identifier.text()).toBe(`${index}${index}`);
    };

    for (let i = 0; i < identifiers.length; i += 1) {
      checkIdentifier(i);
    }
  });

  describe('file link', () => {
    const file = () => getById('file').find(GlLink);

    it('shows only the file name if there is no start line', () => {
      createWrapper({ location: { file: 'test.txt', blob_path: 'blob_path.txt' } });
      expect(file().attributes('target')).toBe('_blank');
      expect(file().attributes('href')).toBe('blob_path.txt');
      expect(file().text()).toBe('test.txt');
    });

    it('shows the correct line number when there is a start line', () => {
      createWrapper({ location: { file: 'test.txt', start_line: 24, blob_path: 'blob.txt' } });
      expect(file().attributes('target')).toBe('_blank');
      expect(file().attributes('href')).toBe('blob.txt#L24');
      expect(file().text()).toBe('test.txt:24');
    });

    it('shows the correct line numbers when there is a start and end line', () => {
      createWrapper({
        location: { file: 'test.txt', start_line: 24, end_line: 27, blob_path: 'blob.txt' },
      });
      expect(file().attributes('target')).toBe('_blank');
      expect(file().attributes('href')).toBe('blob.txt#L24-27');
      expect(file().text()).toBe('test.txt:24-27');
    });

    it('shows only the start line when the end line is the same', () => {
      createWrapper({
        location: { file: 'test.txt', start_line: 24, end_line: 24, blob_path: 'blob.txt' },
      });
      expect(file().attributes('target')).toBe('_blank');
      expect(file().attributes('href')).toBe('blob.txt#L24');
      expect(file().text()).toBe('test.txt:24');
    });
  });
});
