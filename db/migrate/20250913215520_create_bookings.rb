class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bike, null: false, foreign_key: true
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.string :status, default: 'pending'
      t.decimal :total_cost, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
