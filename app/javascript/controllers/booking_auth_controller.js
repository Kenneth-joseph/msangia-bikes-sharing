// app/javascript/controllers/booking_auth_controller.js
import { Controller } from "@hotwired/stimulus"
import { fetchWithAuth } from "../utils/fetch_helper"

/**
 * Booking Authentication Controller
 * Handles the dynamic booking authentication flow with minimal page reloads
 * @extends Controller
 */
export default class extends Controller {
    static targets = ["modal", "phoneSection", "emailSection", "otpSection", "errorMessage", "successMessage"]
    static values = {
        checkPhoneUrl: String,
        createUserUrl: String,
        verifyOtpUrl: String,
        resendOtpUrl: String,
        bookingParams: Object
    }

    /**
     * Initializes the controller
     * Sets up the modal and initial state
     */
    connect() {
        this.showModal()
        this.resetForm()
    }

    /**
     * Shows the authentication modal
     */
    showModal() {
        this.modalTarget.classList.remove('hidden')
    }

    /**
     * Hides the authentication modal
     */
    hideModal() {
        this.modalTarget.classList.add('hidden')
    }

    /**
     * Resets the form to its initial state
     */
    resetForm() {
        this.phoneSectionTarget.classList.remove('hidden')
        this.emailSectionTarget.classList.add('hidden')
        this.otpSectionTarget.classList.add('hidden')
        this.errorMessageTarget.classList.add('hidden')
        this.successMessageTarget.classList.add('hidden')
    }

    /**
     * Handles phone number submission
     * Checks if user exists with the provided phone number
     * @param {Event} event - The form submission event
     */
    async submitPhone(event) {
        event.preventDefault()

        const formData = new FormData(event.target)
        const phone = formData.get('phone')

        try {
            const response = await fetch(this.checkPhoneUrlValue, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                },
                body: JSON.stringify({ phone })
            })

            const data = await response.json()

            if (data.status === 'otp_sent') {
                // User exists, show OTP section
                this.userId = data.user_id
                this.phoneSectionTarget.classList.add('hidden')
                this.otpSectionTarget.classList.remove('hidden')
                this.showMessage('success', 'OTP sent to your phone and email.')
            } else if (data.status === 'email_required') {
                // New user, show email section
                this.phoneNumber = phone
                this.phoneSectionTarget.classList.add('hidden')
                this.emailSectionTarget.classList.remove('hidden')
            }
        } catch (error) {
            this.showMessage('error', 'An error occurred. Please try again.')
        }
    }

    /**
     * Handles email submission for new users
     * Creates a new user with phone and email
     * @param {Event} event - The form submission event
     */
    async submitEmail(event) {
        event.preventDefault()

        const formData = new FormData(event.target)
        const email = formData.get('email')

        try {
            const response = await fetch(this.createUserUrlValue, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                },
                body: JSON.stringify({
                    phone: this.phoneNumber,
                    email: email,
                    booking_params: this.bookingParamsValue
                })
            })

            const data = await response.json()

            if (data.status === 'otp_sent') {
                // User created, show OTP section
                this.userId = data.user_id
                this.emailSectionTarget.classList.add('hidden')
                this.otpSectionTarget.classList.remove('hidden')
                this.showMessage('success', 'OTP sent to your phone and email.')
            } else if (data.errors) {
                // Show validation errors
                this.showMessage('error', this.formatErrors(data.errors))
            }
        } catch (error) {
            this.showMessage('error', 'An error occurred. Please try again.')
        }
    }

    /**
     * Handles OTP verification
     * Verifies the OTP and completes the booking process
     * @param {Event} event - The form submission event
     */
    async verifyOtp(event) {
        event.preventDefault()

        const formData = new FormData(event.target)
        const otp = formData.get('otp')

        try {
            const response = await fetch(this.verifyOtpUrlValue, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                },
                body: JSON.stringify({
                    user_id: this.userId,
                    otp: otp
                })
            })

            const data = await response.json()

            if (data.status === 'success') {
                // OTP verified, complete booking
                this.completeBooking()
            } else {
                this.showMessage('error', 'Invalid OTP. Please try again.')
            }
        } catch (error) {
            this.showMessage('error', 'An error occurred. Please try again.')
        }
    }

    /**
     * Resends OTP to the user
     */
    async resendOtp() {
        try {
            const response = await fetch(this.resendOtpUrlValue, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                },
                body: JSON.stringify({ user_id: this.userId })
            })

            const data = await response.json()

            if (data.status === 'otp_resent') {
                this.showMessage('success', 'OTP has been resent.')
            }
        } catch (error) {
            this.showMessage('error', 'Failed to resend OTP. Please try again.')
        }
    }

    /**
     * Completes the booking process after successful authentication
     */
    async completeBooking() {
        try {
            // Create the booking with the stored parameters
            const response = await fetch('/bookings', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                },
                body: JSON.stringify({
                    booking: this.bookingParamsValue
                })
            })

            if (response.ok) {
                this.showMessage('success', 'Booking confirmed successfully!')
                // Redirect to booking details or show success message
                setTimeout(() => {
                    window.location.href = '/bookings'
                }, 2000)
            } else {
                this.showMessage('error', 'Failed to create booking. Please try again.')
            }
        } catch (error) {
            this.showMessage('error', 'An error occurred. Please try again.')
        }
    }

    /**
     * Displays a message to the user
     * @param {String} type - The type of message (success or error)
     * @param {String} message - The message to display
     */
    showMessage(type, message) {
        if (type === 'success') {
            this.successMessageTarget.textContent = message
            this.successMessageTarget.classList.remove('hidden')
            this.errorMessageTarget.classList.add('hidden')
        } else {
            this.errorMessageTarget.textContent = message
            this.errorMessageTarget.classList.remove('hidden')
            this.successMessageTarget.classList.add('hidden')
        }
    }

    /**
     * Formats error messages from the server
     * @param {Object} errors - The error object from the server
     * @returns {String} Formatted error message
     */
    formatErrors(errors) {
        return Object.entries(errors)
            .map(([field, messages]) => `${field} ${messages.join(', ')}`)
            .join('. ')
    }
}