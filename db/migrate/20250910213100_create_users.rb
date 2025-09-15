class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :phone_number, null: false
      t.string :provider
      t.string :uid

      t.timestamps
    end
    
    add_index :users, :phone_number, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end
