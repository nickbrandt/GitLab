# frozen_string_literal: true

# These shared examples must be run with use_transactional_tests disabled.
# To do this, add a :delete filter to the example `context`. E.g.
#
# context 'Constrained insertions', :delete do
#   subject { Namespace.insert!(name: 'abc', path: 'abc123') }
#   it_behaves_like 'traversal_ids constraint violation'
# end

# Perform SQL commands within BEGIN and COMMIT statements. We roll our own
# wrapper because `#transaction` is unable to handle
# ActiveRecord::StatementInvalid appropriately.
def within_transaction(&blk)
  ActiveRecord::Base.connection.begin_db_transaction
  blk.call
  ActiveRecord::Base.connection.commit_db_transaction
end

RSpec.shared_examples 'constraint violation' do
  it 'triggers an invalid statement' do
    expect do
      within_transaction { subject }
    end.to raise_error(ActiveRecord::StatementInvalid, /PG::RaiseException/)
  end
end

RSpec.shared_examples 'no constraint violation' do
  it 'does not trigger an invalid statement' do
    expect do
      within_transaction { subject }
    end.not_to raise_error
  end
end
