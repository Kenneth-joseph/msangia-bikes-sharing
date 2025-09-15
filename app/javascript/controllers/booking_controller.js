// app/javascript/controllers/booking_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * Booking Controller
 * Handles the bike booking process including availability checks, OTP verification, and payment initiation
 * @extends Controller
 */
export default class extends Controller {
    // Target elements in the DOM
    static targets = ["bike", "slot", "otpModal", "countdown", "paymentButton"]

    // Values passed from the HTML data attributes
    static values = {
        bikeId: Number,        // ID of the selected bike
        userId: Number,        // ID of the current user
        availableSlots: Array  // Array of available time slots
    }

    /**
     * Initializes the controller when connected to the DOM
     * Updates available slots display
     * @return {void}
     * @example Trigger: Automatically when controller connects to DOM element
     */
    connect() {
        this.updateAvailableSlots()
    }

    /**
     * Checks bike availability for the next 30 minutes
     * Sends AJAX request to server to verify availability
     * @return {void}
     * @example Trigger: User clicks "Check Availability" button
     * @example Expected: Creates booking if available, shows message if not
     */
    checkAvailability() {
        const startTime = new Date()
        const endTime = new Date(startTime.getTime() + 30 * 60000)

        fetch('/bikes/check_availability', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({
                bike_id: this.bikeIdValue,
                start_time: startTime.toISOString(),
                end_time: endTime.toISOString()
            })
        })
            .then(response => response.json())
            .then(data => {
                if (data.available) {
                    this.createBooking(startTime, endTime)
                } else {
                    this.showUnavailableMessage()
                }
            })
    }

    /**
     * Creates a booking in the background via a background job
     * @param {Date} startTime - Start time of the booking
     * @param {Date} endTime - End time of the booking
     * @return {void}
     * @example Trigger: After successful availability check
     * @example Expected: Background job created and OTP modal shown
     */
    createBooking(startTime, endTime) {
        BookingCreationJob.perform_later(
            this.userIdValue,
            this.bikeIdValue,
            startTime.toISOString(),
            endTime.toISOString()
        )

        this.showOtpModal()
    }

    /**
     * Displays the OTP verification modal
     * @return {void}
     * @example Trigger: After booking creation
     * @example Expected: OTP modal becomes visible
     */
    showOtpModal() {
        this.otpModalTarget.classList.remove('hidden')
    }

    /**
     * Verifies the OTP code entered by the user
     * @return {void}
     * @example Trigger: User submits OTP form
     * @example Expected: Initiates payment if OTP is valid, shows error if invalid
     */
    verifyOtp() {
        const otp = document.getElementById('otp-input').value

        fetch('/bookings/verify_otp', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({
                otp: otp,
                booking_id: this.bookingId
            })
        })
            .then(response => response.json())
            .then(data => {
                if (data.verified) {
                    this.initiatePayment()
                } else {
                    this.showOtpError()
                }
            })
    }

    /**
     * Initiates the payment process (STK push simulation)
     * @return {void}
     * @example Trigger: After successful OTP verification
     * @example Expected: Disables payment button and starts countdown
     */
    initiatePayment() {
        this.paymentButtonTarget.disabled = true
        this.startCountdown()

        // Simulate STK push (replace with actual payment integration)
        setTimeout(() => {
            this.completeBooking()
        }, 5000)
    }

    /**
     * Starts a countdown timer for payment completion
     * @return {void}
     * @example Trigger: After payment initiation
     * @example Expected: Countdown display updates every second
     */
    startCountdown() {
        let seconds = 60
        this.countdownInterval = setInterval(() => {
            this.countdownTarget.textContent = `00:${seconds.toString().padStart(2, '0')}`
            seconds--

            if (seconds < 0) {
                clearInterval(this.countdownInterval)
                this.bookingExpired()
            }
        }, 1000)
    }

    /**
     * Updates the display of available time slots
     * @return {void}
     * @example Trigger: On controller connection and when slots change
     * @example Expected: Available slots are displayed to the user
     */
    updateAvailableSlots() {
        // Implementation would update the slotTargets with availableSlotsValue
    }

    /**
     * Displays a message when the bike is unavailable
     * @return {void}
     * @example Trigger: When availability check returns unavailable
     * @example Expected: User sees an unavailable message
     */
    showUnavailableMessage() {
        // Implementation would show an error message
    }

    /**
     * Displays an error message for invalid OTP
     * @return {void}
     * @example Trigger: When OTP verification fails
     * @example Expected: User sees an OTP error message
     */
    showOtpError() {
        // Implementation would show an OTP error message
    }

    /**
     * Handles the booking completion process
     * @return {void}
     * @example Trigger: After successful payment simulation
     * @example Expected: Booking is marked as complete
     */
    completeBooking() {
        // Implementation would complete the booking process
    }

    /**
     * Handles the booking expiration when countdown completes
     * @return {void}
     * @example Trigger: When countdown reaches zero
     * @example Expected: Booking is cancelled or expired
     */
    bookingExpired() {
        // Implementation would handle expired booking
    }
}