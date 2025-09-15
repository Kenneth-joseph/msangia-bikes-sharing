class CreateBikes < ActiveRecord::Migration[8.0]
  def change
    create_table :bikes do |t|
      t.string :name
      t.string :model
      t.string :tag_number
      t.string :location
      t.string :color
      t.boolean :available

      t.timestamps
    end
  end
end
