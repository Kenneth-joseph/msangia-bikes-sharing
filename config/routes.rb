Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  resources :bikes do
    resources :bookings, only: [ :new, :create ]
  end

  resources :bookings, only: [:create] do
    post 'confirm', on: :member, action: :confirm_booking
  end

  post "/bikes/check_availability", to: "bookings#check_availability"



  # Guest authentication routes
  namespace :guest do
    # Single endpoint for both checking phone and creating user
    post "auth", to: "auth#create"
    put "auth", to: "auth#update"
    post "auth/verify_otp", to: "auth#verify_otp"
    post "auth/resend_otp", to: "auth#resend_otp"
  end


  # Booking authentication flow routes
  # Provides a simplified authentication flow for booking-only users
  scope module: :booking do
    # GET /booking/auth
    # Displays phone number entry form for booking authentication
    get "booking/auth", to: "auth#new", as: :booking_auth

    # POST /booking/auth
    # Processes phone number submission for booking authentication
    post "booking/auth", to: "auth#create"

    # GET /booking/email
    # Displays email entry form for new booking users
    get "booking/email", to: "auth#email", as: :booking_email

    # POST /booking/email
    # Creates new user account for booking
    post "booking/email", to: "auth#create_user"

    # GET /booking/otp_verify
    # Displays OTP verification form
    get "booking/otp_verify", to: "auth#otp_verify", as: :booking_otp_verify

    # POST /booking/otp_verify
    # Verifies OTP code and signs in user
    post "booking/otp_verify", to: "auth#verify_otp"

  end
end
