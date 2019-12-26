# frozen_string_literal: true

shared_examples 'skips validation' do |args, options|
  it 'skips validation' do
    expect(model).not_to receive(:disable_statement_timeout)
    expect(model).to receive(:execute).with(/ADD CONSTRAINT/)
    expect(model).not_to receive(:execute).with(/VALIDATE CONSTRAINT/)

    model.add_concurrent_foreign_key(*args, **options)
  end
end

shared_examples 'performs validation' do |args, options|
  it 'performs validation' do
    expect(model).to receive(:disable_statement_timeout).and_call_original
    expect(model).to receive(:execute).with(/statement_timeout/)
    expect(model).to receive(:execute).ordered.with(/NOT VALID/)
    expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
    expect(model).to receive(:execute).with(/RESET ALL/)

    model.add_concurrent_foreign_key(*args, **options)
  end
end
