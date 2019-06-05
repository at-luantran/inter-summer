class ChangeIndexEmailOfUser < ActiveRecord::Migration[5.2]
  def up
    remove_index :users, :email
    add_index :users, :email, unique: true, where: 'deleted_at IS NULL'
  end

  def down
    remove_index :users, :email
    add_index :users, :email, unique: true
  end
end
