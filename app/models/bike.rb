class Bike < ApplicationRecord
  # associations
  has_many :bookings
  has_many :users, through: :bookings

  # validations
  validates_presence_of :name, :model, :tag_number, :color
  validates :available, inclusion: { in: [ true, false ] }

  # scope
  scope :available, -> { where(available: true) }

  # Scope for bikes at specific location
  scope :at_location, ->(location) { where(location: location) }

  # Scope for bikes that are available at a specific location
  scope :available_at, ->(location) { available.at_location(location) }

  # Scope for bikes that have been maintained recently
  scope :recently_maintained, -> { where("last_maintenance_date >= ?", 1.month.ago) }

  # Complex scope with joins (bikes with no active bookings)
  scope :with_no_active_bookings, -> {
    left_joins(:bookings)
      .where(bookings: { id: nil })
      .or(where.not(bookings: { status: :active }))
      .distinct
  }

  # Scope for unavailable bikes
  scope :unavailable, -> { where(available: false) }

  # scope for available bikes with bookings
  scope :available_with_bookings, -> { available.includes(:bookings) }


  # Check if bike is available for a given time slot
  # @param start_time [DateTime] the start time of the booking
  # @param end_time [DateTime] the end time of the booking
  # @return [Boolean] true if the bike is available for the given slot
  def available_for_slot?(start_time, end_time)
    return false unless available

    # Check for overlapping bookings
    bookings.where.not(status: "cancelled")
            .where("(start_time <= ? AND end_time >= ?) OR (start_time <= ? AND end_time >= ?)",
                   end_time, start_time, start_time, end_time)
            .none?
  end
end
