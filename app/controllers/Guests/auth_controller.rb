# app/controllers/guest/auth_controller.rb
class Guest::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_booking_params, only: [:create, :update]

  # Handles phone number submission for guest authentication
  # Checks if user exists with the provided phone number
  # @param phone [String] The user's phone number
  # @return [JSON] Response indicating if OTP was sent or if email is required
  # @example Trigger: AJAX request from booking auth modal
  # @example Usage: { phone: "+1234567890" }
  # @example Expected Success: { status: 'otp_sent', user_id: 1 }
  # @example Expected New User: { status: 'email_required' }
  def create
    phone = params[:phone]
    user = User.find_by(phone_number: phone)

    if user
      send_otp(user)
      render json: { status: "otp_sent", user_id: user.id }
    else
      # Store booking params in session for later use
      session[:booking_params] = @booking_params if @booking_params
      session[:phone_number] = phone
      render json: { status: "email_required" }
    end
  end

  # Handles user registration for new guest users
  # Creates a new user with phone number and email
  # @param :phone [String] The user's phone number
  # @param :email [String] The user's email address
  # @param :booking_params [Hash] Optional booking parameters to store in session
  # @return [JSON] Response indicating if OTP was sent or validation errors
  # @example Trigger: AJAX request from booking auth modal
  # @example Usage: { phone: "+1234567890", email: "user@example.com", booking_params: { bike_id: 1, start_time: "...", end_time: "..." } }
  # @example Expected Success: { status: 'otp_sent', user_id: 1 }
  # @example Expected Error: { errors: { email: 'is already registered...' } }
  def update
    phone = params[:phone] || session[:phone_number]
    email = params[:email]

    # Check if email is already taken
    existing_user = User.find_by(email: email)
    if existing_user
      render json: {
        errors: { email: "is already registered. Please use the phone number associated with this account." } },
             status: :unprocessable_entity
      return
    end

    user = User.new(phone_number: phone, email: email, role: :client)
    user.password = Devise.friendly_token[0, 20]

    if user.save
      # Store booking params in session for later use
      session[:booking_params] = @booking_params if @booking_params
      session[:user_id] = user.id

      send_otp(user)
      render json: { status: "otp_sent", user_id: user.id }
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  # Verifies the OTP code provided by the user
  # Signs in the user upon successful verification
  # @param :user_id [Integer] The ID of the user to verify
  # @param :otp [String] The OTP code entered by the user
  # @return [JSON] Response indicating success or failure of OTP verification
  # @example Trigger: AJAX request from booking auth modal
  # @example Usage: { user_id: 1, otp: "123456" }
  # @example Expected Success: { status: 'success' }
  # @example Expected Error: { errors: 'Invalid OTP' }
  def verify_otp
    user = User.find(params[:user_id])

    if user.validate_and_consume_otp!(params[:otp])
      sign_in(user, event: :authentication)
      # Create booking from session if exists
      create_booking_from_session(user)

      render json: { status: "success" }
    else
      render json: { errors: "Invalid OTP" }, status: :unprocessable_entity
    end
  end

  # Resends OTP to the user's phone and email
  # @param :user_id [Integer] The ID of the user to resend OTP to
  # @return [JSON] Response indicating OTP was resent
  # @example Trigger: AJAX request from booking auth modal
  # @example Usage: { user_id: 1 }
  # @example Expected: { status: 'otp_resent' }
  def resend_otp
    user = User.find(params[:user_id])
    send_otp(user)
    render json: { status: "otp_resent" }
  end

  private

  # Sets booking parameters from request
  # @return [void]
  def set_booking_params
    @booking_params = params[:booking_params]
  end

  # Sends OTP to the user's phone and email
  # @param user [User] The user to send OTP to
  # @return [void]
  def send_otp(user)
    # Generate a new OTP
    user.generate_otp
    user.save
    # Send via SMS
    SmsService.send_otp(user.phone_number, user.current_otp) if user.phone_number.present?
    # Send via email
    UserMailer.otp_email(user).deliver_later if user.email.present?
  end

  # Creates a booking from session data if it exists
  # @param user [User] The user to associate the booking with
  # @return [void]
  def create_booking_from_session(user)
    return unless session[:booking_params].present?

    booking = user.bookings.new(session[:booking_params])
    if booking.save
      session.delete(:booking_params)
      session.delete(:phone_number)
      session.delete(:user_id)
    else
      # Log error but don't raise exception
      Rails.logger.error "Failed to create booking from session: #{booking.errors.full_messages}"
    end
  end
end