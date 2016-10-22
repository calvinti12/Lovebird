class CreateRelationships < ActiveRecord::Migration[5.0]
  def change
    create_table :relationships do |t|
      t.string :user_id
      t.string :crush_id
      t.integer :status
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
    add_index :relationships, :user_id, unique: true
  end
end
