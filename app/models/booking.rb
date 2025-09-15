# app/models/booking.rb
class Booking < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :bike

  # Enums
  enum status: { pending: 0, confirmed: 1, active: 2, completed: 3, cancelled: 4 }

  # Validations
  validates :start_time, :end_time, presence: true
  validate :validate_booking_slot

  # Callbacks
  before_create :generate_otp
  after_create :schedule_booking_reminders

  # Check if a time slot is valid (at least 30 minutes, max 1 week ahead)
  # @param start_time [DateTime] the proposed start time
  # @param end_time [DateTime] the proposed end time
  # @return [Boolean] true if the slot is valid
  def valid_slot?(start_time, end_time)
    return false if start_time < Time.current
    return false if end_time < start_time + 30.minutes
    return false if start_time > Time.current + 1.week

    true
  end


  # Verifies the OTP for booking confirmation
  # @param otp [String] The OTP code to verify
  # @return [Boolean] True if OTP is valid
  def verify_otp(otp)
    self.otp == otp && otp_expires_at > Time.current
  end

  def generate_booking_otp
    self.otp = rand(100000..999999).to_s
    self.otp_expires_at = Time.current + 5.minutes
  end

  # Confirms the booking
  # @return [Boolean] True if booking was confirmed
  def confirm!
    update(status: :confirmed, confirmed_at: Time.current)
  end

  # Calculates the cost of the booking
  # @return [Decimal] The total cost
  def calculate_cost
    hours = (end_time - start_time) / 1.hour
    hours * bike.hourly_rate
  end

  private

  def validate_booking_slot
    errors.add(:base, 'Invalid booking slot') unless valid_slot?(start_time, end_time)
    errors.add(:base, 'Bike not available for this slot') unless bike.available_for_slot?(start_time, end_time)
  end


  def schedule_booking_reminders
    # Schedule reminder job 10 minutes before booking starts
    BookingReminderJob.set(wait_until: start_time - 10.minutes).perform_later(id)

    # Schedule completion check job at booking end time
    BookingCompletionJob.set(wait_until: end_time).perform_later(id)
  end
end