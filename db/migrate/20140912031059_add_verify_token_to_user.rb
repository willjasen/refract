class AddVerifyTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :verify_token, :string
  end
end
