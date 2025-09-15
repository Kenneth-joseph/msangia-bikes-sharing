class AddIndexesToBikes < ActiveRecord::Migration[8.0]
  def change
    add_index :bikes, [:available, :location] # Composite index
  end
end
