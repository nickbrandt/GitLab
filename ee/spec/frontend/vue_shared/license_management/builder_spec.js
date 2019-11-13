import { Builder } from '../../license_management/mock_data';

describe('build', () => {
  it('creates a v1 report', () => {
    const result = Builder.forV1()
      .addLicense({ name: 'MIT License' })
      .addDependency({ name: 'rails', license: { name: 'MIT License' } })
      .build();

    expect(result).toMatchObject({
      licenses: [{ name: 'MIT License', url: 'https://opensource.org/licenses/MIT', count: 0 }],
      dependencies: [
        {
          license: { name: 'MIT License', url: 'https://opensource.org/licenses/MIT' },
          dependency: { name: 'rails', description: 'RAILS', url: 'https://www.example.org/rails' },
        },
      ],
    });
  });

  it('creates a v1.1 report', () => {
    const result = Builder.forV1('1')
      .addLicense({ name: 'MIT License' })
      .addDependency({ name: 'rails', license: { name: 'MIT License' } })
      .build();

    expect(result).toMatchObject({
      version: '1.1',
      licenses: [{ name: 'MIT License', url: 'https://opensource.org/licenses/MIT', count: 0 }],
      dependencies: [
        {
          license: { name: 'MIT License', url: 'https://opensource.org/licenses/MIT' },
          licenses: [{ name: 'MIT License', url: 'https://opensource.org/licenses/MIT' }],
          dependency: { name: 'rails', description: 'RAILS', url: 'https://www.example.org/rails' },
        },
      ],
    });
  });

  it('creates a v2 report', () => {
    const result = Builder.forV2()
      .addLicense({ id: 'MIT', name: 'MIT License' })
      .addDependency({ name: 'rails', licenses: ['MIT'] })
      .build();
    expect(result).toMatchObject({
      version: '2.0',
      licenses: [{ id: 'MIT', name: 'MIT License', url: 'https://opensource.org/licenses/MIT' }],
      dependencies: [{ name: 'rails', description: 'RAILS', licenses: ['MIT'] }],
    });
  });
});
