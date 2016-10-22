class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :facebook_id
      t.string :first_name
      t.string :last_name
      t.string :pro_pic

      t.timestamps
    end
    add_index :users, :facebook_id, unique: true
    add_index :users, :first_name
    add_index :users, :last_name
  end
end
