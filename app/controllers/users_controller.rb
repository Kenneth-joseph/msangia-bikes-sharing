# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # GET /users
  # Displays all users with pagination
  # @return [HTML] Renders the users index view
  def index
    @users = policy_scope(User).order(created_at: :desc).page(params[:page])
    authorize @users
  end

  # GET /users/1
  # Shows details of a specific user
  # @return [HTML] Renders the user show view
  def show
    authorize @user
  end

  # GET /users/1/edit
  # Displays form to edit a user
  # @return [HTML] Renders the user edit form
  def edit
    authorize @user
  end

  # PATCH/PUT /users/1
  # Updates a user's information
  # @return [HTML] Redirects to user show view on success, re-renders edit form on failure
  def update
    authorize @user
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /users/1
  # Deletes a user account
  # @return [HTML] Redirects to users index with notice
  def destroy
    authorize @user
    @user.destroy
    redirect_to users_url, notice: 'User was successfully deleted.'
  end

  # POST /users/send_otp
  # Sends OTP to user's phone and email for verification
  # @return [JSON] JSON response with status
  def send_otp
    @user = User.find(params[:id])
    authorize @user

    # Send OTP via SMS and email
    if SmsService.send_otp(@user.phone_number, @user.current_otp) &&
       UserMailer.send_otp(@user).deliver_later
      render json: { status: 'success', message: 'OTP sent successfully' }
    else
      render json: { status: 'error', message: 'Failed to send OTP' }, status: :unprocessable_entity
    end
  end

  # POST /users/verify_otp
  # Verifies the OTP provided by the user
  # @param :otp [String] The OTP code entered by the user
  # @return [JSON] JSON response with verification status
  def verify_otp
    @user = User.find(params[:id])
    authorize @user

    if @user.validate_and_consume_otp!(params[:otp])
      @user.update(otp_verified: true, otp_verified_at: Time.current)
      render json: { status: 'success', message: 'OTP verified successfully' }
    else
      render json: { status: 'error', message: 'Invalid OTP' }, status: :unprocessable_entity
    end
  end

  private

  # Sets the user instance variable based on ID parameter
  # @return [User] The user object
  def set_user
    @user = User.find(params[:id])
  end

  # Defines permitted parameters for user updates
  # @return [ActionController::Parameters] Permitted user parameters
  def user_params
    params.require(:user).permit(:name, :email, :phone_number, :avatar, role_ids: [])
  end
end