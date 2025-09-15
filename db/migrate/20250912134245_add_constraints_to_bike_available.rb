class AddConstraintsToBikeAvailable < ActiveRecord::Migration[8.0]
  def change
    change_column :bikes, :available, :boolean, default: true, null: false
  end
end
