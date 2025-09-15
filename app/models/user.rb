# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # OTP verification
  devise :otp_authenticatable, :otp_backupable

  # Rolify for role management
  rolify

  # Associations
  has_many :bookings
  has_many :bikes, through: :bookings

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :phone_number, presence: true, uniqueness: true

  # Add guest user validation
  validate :guest_user_validation, if: :guest?

  # Callbacks
  before_create :generate_otp_secret
  after_create :assign_default_role

  # Google OAuth
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      # Assuming phone number is not available from Google
      user.phone_number = "temp_#{SecureRandom.hex(8)}"
      user.skip_confirmation!
    end
  end

  # Generates a time-based one-time password (TOTP)
  # @return [String] The generated OTP code
  # @example Trigger: When sending OTP for authentication
  # @example Usage: user.generate_otp
  # @example Expected: Returns a 6-digit OTP code
  def generate_otp
    self.otp_secret = User.generate_otp_secret if otp_secret.blank?
    self.otp_counter = (otp_counter || 0) + 1
    save(validate: false)

    ROTP::TOTP.new(otp_secret).now
  end

  # Validate OTP
  # Validates and consumes an OTP code
  # @param otp [String] The OTP code to validate
  # @return [Boolean] True if OTP is valid, false otherwise
  # @example Trigger: When verifying OTP during authentication
  # @example Usage: user.validate_and_consume_otp!("123456")
  # @example Expected: Returns true if OTP is valid, false otherwise
  def validate_and_consume_otp!(otp)
    totp = ROTP::TOTP.new(otp_secret)
    result = totp.verify(otp, drift_behind: 60)

    if result
      update(otp_counter: otp_counter + 1)
      true
    else
      false
    end
  end



  private

  # Checks if user is a guest (booking-only) user
  # @return [Boolean] True if user is a guest, false otherwise
  # @example Trigger: When determining user permissions
  # @example Usage: user.guest?
  # @example Expected: Returns true if user was created through booking flow
  def guest?
    guest
  end

  # Validates guest users with different rules
  # @return [void]
  # @example Trigger: During user validation
  # @example Expected: Applies different validation rules for guest users
  def guest_user_validation
    errors.add(:phone_number, "can't be blank") if phone_number.blank?
  end

  # Determines if password is required for this user
  # Overrides Devise's default behavior for guest users
  # @return [Boolean] False for guest users, otherwise follows default behavior
  # @example Trigger: During user validation
  # @example Expected: Returns false for guest users
  def password_required?
    return false if guest?
    super
  end

  # Determines if email is required for this user
  # Overrides Devise's default behavior for guest users
  # @return [Boolean] False for guest users, otherwise follows default behavior
  # @example Trigger: During user validation
  # @example Expected: Returns false for guest users
  def email_required?
    return false if guest?
    super
  end


  def assign_default_role
    add_role(:client) if roles.blank?
  end

  def generate_otp_secret
    self.otp_secret = User.generate_otp_secret
  end
end