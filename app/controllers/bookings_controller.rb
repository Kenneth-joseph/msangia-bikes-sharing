# app/controllers/bookings_controller.rb
class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bike, only: [ :new, :create ]
  before_action :set_booking, only: [ :show, :edit, :update, :destroy ]

  # GET /bookings/new
  # Shows the booking form for a specific bike
  # @return [HTML] Renders the booking form
  def new
    @booking = Booking.new
    @booking.bike = @bike
    @booking.user = current_user
    @booking.start_time = Time.current
    @booking.end_time = 30.minutes.from_now
  end

  # POST /bookings
  # Creates a new booking
  # @return [Redirect] Redirects to booking show page on success, back to form on failure
  def create
    @booking = current_user.bookings.new(booking_params)
    @booking.bike = @bike

    if @booking.save
      # Send OTP for confirmation
      send_booking_otp(@booking)
      redirect_to booking_path(@booking), notice: 'Booking created successfully. Please verify OTP to confirm.'
    else
      render :new
    end
  end

  # GET /bookings/1
  # Shows booking details
  # @return [HTML] Renders the booking show page
  def show
    authorize @booking
  end

  # POST /bookings/verify_otp
  # Verifies OTP for booking confirmation
  # @param otp [String] The OTP code
  # @param booking_id [Integer] The booking ID
  # @return [JSON] JSON response with verification status
  def verify_otp
    @booking = Booking.find(params[:booking_id])
    authorize @booking

    if @booking.verify_otp(params[:otp])
      @booking.confirm!
      initiate_payment(@booking)
      render json: { status: 'success', message: 'Booking confirmed!' }
    else
      render json: { status: 'error', message: 'Invalid OTP' }, status: :unprocessable_entity
    end
  end

  # POST /bikes/check_availability
  # Checks if a bike is available for a given time slot
  # @param bike_id [Integer] The bike ID
  # @param start_time [DateTime] Start time of the booking
  # @param end_time [DateTime] End time of the booking
  # @return [JSON] JSON response with availability status
  def check_availability
    bike = Bike.find(params[:bike_id])
    start_time = Time.zone.parse(params[:start_time])
    end_time = Time.zone.parse(params[:end_time])

    available = bike.available_for_slot?(start_time, end_time)

    render json: { available: available }
  end


  def confirm_booking
    @booking = Booking.find(params[:booking_id])
    if @booking.verify_otp(params[:otp]) # Assume you have a method to verify OTP in Booking model
      @booking.update(status: 'confirmed')
      initiate_payment(@booking)
      render json: { status: 'success', message: 'Booking confirmed!' }
    else
      render json: { errors: 'Invalid OTP' }, status: :unprocessable_entity
    end
  end
  private

  def set_bike
    @bike = Bike.find(params[:bike_id])
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:start_time, :end_time, :bike_id)
  end

  def send_booking_otp(booking)
    # Generate and send OTP
    otp = booking.generate_booking_otp
    # Send via SMS
    SmsService.send_otp(current_user.phone_number, otp) if current_user.phone_number.present?
    # Send via email
    UserMailer.booking_otp(current_user, booking).deliver_later if current_user.email.present?
  end

  def initiate_payment(booking)
    # Initiate payment process
    PaymentService.initiate_stk_push(
      phone_number: current_user.phone_number,
      amount: booking.calculate_cost,
      booking_id: booking.id
    )
  end
end