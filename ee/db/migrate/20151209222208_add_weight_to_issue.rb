class AddWeightToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :weight, :integer
  end
end
