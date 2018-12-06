class AddNoteToUsers < ActiveRecord::Migration[4.2]
  def up
    # Column "note" has been added to schema mistakenly (without actual migration),
    # and this is why it can exist in some instances.
    unless column_exists?(:users, :note)
      add_column :users, :note, :text
    end
  end

  def down
  end
end
