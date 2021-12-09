//
//  STPBlocks.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

/// These values control the labels used in the shipping info collection form.
@objc public enum STPShippingType: Int {
    /// Shipping the purchase to the provided address using a third-party
    /// shipping company.
    case shipping
    /// Delivering the purchase by the seller.
    case delivery
}

/// An enum representing the status of a shipping address validation.
@objc public enum STPShippingStatus: Int {
    /// The shipping address is valid.
    case valid
    /// The shipping address is invalid.
    case invalid
}

/// An enum representing the status of a payment requested from the user.
@objc public enum STPPaymentStatus: Int {
    /// The payment succeeded.
    case success
    /// The payment failed due to an unforeseen error, such as the user's Internet connection being offline.
    case error
    /// The user cancelled the payment (for example, by hitting "cancel" in the Apple Pay dialog).
    case userCancellation
}

/// An empty block, called with no arguments, returning nothing.
public typealias STPVoidBlock = () -> Void
/// A block that may optionally be called with an error.
/// - Parameter error: The error that occurred, if any.
public typealias STPErrorBlock = (Error?) -> Void
/// A block that contains a boolean success param and may optionally be called with an error.
/// - Parameters:
///   - success:       Whether the task succeeded.
///   - error:         The error that occurred, if any.
public typealias STPBooleanSuccessBlock = (Bool, Error?) -> Void
/// A callback to be run with a JSON response.
/// - Parameters:
///   - jsonResponse:  The JSON response, or nil if an error occured.
///   - error:         The error that occurred, if any.
public typealias STPJSONResponseCompletionBlock = ([AnyHashable: Any]?, Error?) -> Void
/// A callback to be run with a token response from the Stripe API.
/// - Parameters:
///   - token: The Stripe token from the response. Will be nil if an error occurs. - seealso: STPToken
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPTokenCompletionBlock = (STPToken?, Error?) -> Void
/// A callback to be run with a PaymentIntent response from the Stripe API.
/// - Parameters:
///   - paymentIntent: The Stripe PaymentIntent from the response. Will be nil if an error occurs. - seealso: STPPaymentIntent
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPPaymentIntentCompletionBlock = (STPPaymentIntent?, Error?) -> Void
/// A callback to be run with a PaymentIntent response from the Stripe API.
/// - Parameters:
///   - setupIntent: The Stripe SetupIntent from the response. Will be nil if an error occurs. - seealso: STPSetupIntent
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPSetupIntentCompletionBlock = (STPSetupIntent?, Error?) -> Void
/// A callback to be run with a PaymentMethod response from the Stripe API.
/// - Parameters:
///   - paymentMethod: The Stripe PaymentMethod from the response. Will be nil if an error occurs. - seealso: STPPaymentMethod
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPPaymentMethodCompletionBlock = (STPPaymentMethod?, Error?) -> Void
/// A callback to be run with an array of PaymentMethods response from the Stripe API.
/// - Parameters:
///   - paymentMethods: An array of PaymentMethod from the response. Will be nil if an error occurs. - seealso: STPPaymentMethod
///   - error: The error returned from the response, or nil if none occurs. - seealso: StripeError.h for possible values.
public typealias STPPaymentMethodsCompletionBlock = ([STPPaymentMethod]?, Error?) -> Void
/// An enum representing the success and error states of PIN management
@objc public enum STPPinStatus: Int {
    /// The verification object was already redeemed
    case success
    /// The verification object was already redeemed
    case errorVerificationAlreadyRedeemed
    /// The one-time code was incorrect
    case errorVerificationCodeIncorrect
    /// The verification object was expired
    case errorVerificationExpired
    /// The verification object has been attempted too many times
    case errorVerificationTooManyAttempts
    /// An error occured while retrieving the ephemeral key
    case ephemeralKeyError
    /// An unknown error occured
    case unknownError
}

/// A block called with a payment status and an optional error.
/// - Parameter error: The error that occurred, if any.
public typealias STPPaymentStatusBlock = (STPPaymentStatus, Error?) -> Void
/// A block to be run with the client secret of a PaymentIntent or SetupIntent.
/// - Parameters:
///   - clientSecret:    The client secret of the PaymentIntent or SetupIntent. See https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret
///   - error:                    The error that occurred when creating the Intent, or nil if none occurred.
public typealias STPIntentClientSecretCompletionBlock = (String?, Error?) -> Void

/**
 A callback to be run with an STPRadarSession

 - Parameters:
    - radarSession: The RadarSession object.
    - error: The error that occured, if any.
 */
public typealias STPRadarSessionCompletionBlock = (STPRadarSession?, Error?) -> Void
