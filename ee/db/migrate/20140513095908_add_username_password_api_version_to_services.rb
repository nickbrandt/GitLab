class AddUsernamePasswordApiVersionToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :username, :string
    add_column :services, :password, :string
    add_column :services, :api_version, :string
  end
end
