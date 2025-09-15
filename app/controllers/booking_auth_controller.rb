# app/controllers/booking_auth_controller.rb
class BookingAuthController < ApplicationController
  skip_before_action :authenticate_user!

  # Displays the initial booking authentication form
  # @return [HTML] Renders the phone number entry form
  # @example Trigger: Visiting /booking/auth
  # @example Expected: Shows a form to enter phone number
  def new
    @booking = Booking.new
  end

  # Processes the phone number submission
  # Checks if a user exists with the provided phone number
  # @param :phone_number [String] The user's phone number
  # @return [Redirect] Redirects to OTP verification for existing users or email collection for new users
  # @example Trigger: Submitting the phone number form
  # @example Usage: POST /booking/auth with phone_number: "+1234567890"
  # @example Expected: Redirects based on user's existence
  def create
    phone_number = params[:phone_number]
    @user = User.find_by(phone_number: phone_number)

    if @user
      send_otp_to_phone(@user)
      redirect_to booking_otp_verify_path(phone_number: phone_number)
    else
      redirect_to booking_email_path(phone_number: phone_number)
    end
  end

  # Displays the email collection form for new users
  # @param :phone_number [String] The user's phone number from previous step
  # @return [HTML] Renders the email entry form
  # @example Trigger: Redirect from create action for new users
  # @example Expected: Shows a form to enter email address

  # todo: use stimilus for check whether the client exist and trigger otp send, let the create method ot be doing it
  def email
    @phone_number = params[:phone_number]
  end

  # Creates a new user account with phone number and email
  # @param phone_number [String] The user's phone number
  # @param email [String] The user's email address
  # @return [Redirect] Redirects to OTP verification on success, back to email form on failure
  # @example Trigger: Submitting the email form
  # @example Usage: POST /booking/email with phone_number: "+1234567890", email: "user@example.com"
  # @example Expected: Creates user account and redirects to OTP verification
  def create_user
    phone_number = params[:phone_number]
    email = params[:email]

    @user = User.new(
      phone_number: phone_number,
      email: email,
      password: Devise.friendly_token[0, 20]
    )

    if @user.save
      send_otp_to_email(@user)
      redirect_to booking_otp_verify_path(phone_number: phone_number)
    else
      flash[:error] = "Could not create account: #{@user.errors.full_messages.join(', ')}"
      redirect_to booking_email_path(phone_number: phone_number)
    end
  end

  # Displays the OTP verification form
  # @param phone_number [String] The user's phone number for OTP verification
  # @return [HTML] Renders the OTP entry form
  # @example Trigger: Redirect from create or create_user actions
  # @example Expected: Shows a form to enter OTP code
  def otp_verify
    @phone_number = params[:phone_number]
  end

  # Verifies the submitted OTP code
  # @param phone_number [String] The user's phone number
  # @param otp [String] The OTP code entered by the user
  # @return [Redirect] Signs in the user and redirects to booking on success, back to OTP form on failure
  # @example Trigger: Submitting the OTP form
  # @example Usage: POST /booking/otp_verify with phone_number: "+1234567890", otp: "123456"
  # @example Expected: Signs in user and redirects to booking or shows error
  def verify_otp
    phone_number = params[:phone_number]
    otp = params[:otp]

    @user = User.find_by(phone_number: phone_number)

    if @user && @user.validate_and_consume_otp!(otp)
      sign_in(@user, bypass: true)
      redirect_to new_booking_path, notice: "Successfully verified!"
    else
      flash[:error] = "Invalid OTP. Please try again."
      redirect_to booking_otp_verify_path(phone_number: phone_number)
    end
  end

  private

  # Sends OTP to user's phone number
  # @param user [User] The user to send OTP to
  # @return [Boolean] True if OTP was sent successfully
  # @example Trigger: Called from create action for existing users
  # @example Usage: send_otp_to_phone(user)
  # @example Expected: Sends SMS with OTP code
  def send_otp_to_phone(user)
    otp = user.generate_otp
    SmsService.send_otp(user.phone_number, otp)
  end

  # Sends OTP to user's email address
  # @param user [User] The user to send OTP to
  # @return [Boolean] True if email was sent successfully
  # @example Trigger: Called from create_user action for new users
  # @example Usage: send_otp_to_email(user)
  # @example Expected: Sends email with OTP code
  def send_otp_to_email(user)
    otp = user.generate_otp
    UserMailer.booking_otp(user, otp).deliver_later
  end
end