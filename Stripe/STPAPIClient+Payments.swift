//
//  STPAPIClient.swift
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

import Foundation
import PassKit
import UIKit
@_spi(STP) import StripeCore

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

/// A client for making connections to the Stripe API.
extension STPAPIClient {
    /// The client's configuration.
    /// Defaults to `STPPaymentConfiguration.shared`.
    public var configuration: STPPaymentConfiguration {
        get {
            if let config = _stored_configuration as? STPPaymentConfiguration {
                return config
            } else {
                return .shared
            }
        }
        set {
            _stored_configuration = newValue
        }
    }

    /// Initializes an API client with the given configuration.
    /// - Parameter configuration: The configuration to use.
    /// - Returns: An instance of STPAPIClient.
    @available(
        *, deprecated,
        message:
            "This initializer previously configured publishableKey and stripeAccount via the STPPaymentConfiguration instance. This behavior is deprecated; set the STPAPIClient configuration, publishableKey, and stripeAccount properties directly on the STPAPIClient instead."
    )
    public convenience init(configuration: STPPaymentConfiguration) {
        // For legacy reasons, we'll support this initializer and use the deprecated configuration.{publishableKey, stripeAccount} properties
        self.init()
        publishableKey = configuration.publishableKey
        stripeAccount = configuration.stripeAccount
    }
}

extension STPAPIClient {
    // MARK: Tokens

    func createToken(
        withParameters parameters: [String: Any],
        completion: @escaping STPTokenCompletionBlock
    ) {
        let tokenType = STPAnalyticsClient.tokenType(fromParameters: parameters)
        STPAnalyticsClient.sharedClient.logTokenCreationAttempt(
            with: configuration,
            tokenType: tokenType)
        let preparedParameters = Self.paramsAddingPaymentUserAgent(parameters)
        APIRequest<STPToken>.post(
            with: self,
            endpoint: APIEndpointToken,
            parameters: preparedParameters
        ) { object, _, error in
            completion(object, error)
        }
    }
}

// MARK: Personally Identifiable Information

/// STPAPIClient extensions to create Stripe tokens from a personal identification number.
extension STPAPIClient {
    /// Converts a personal identification number into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - pii: The user's personal identification number. Cannot be nil. - seealso: https://stripe.com/docs/api#create_pii_token
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    public func createToken(
        withPersonalIDNumber pii: String, completion: STPTokenCompletionBlock?
    ) {
        var params: [String: Any] = [
            "pii": [
                "personal_id_number": pii
            ]
        ]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        if let completion = completion {
            createToken(withParameters: params, completion: completion)
        }
        STPTelemetryClient.shared.sendTelemetryData()
    }

    /// Converts the last 4 SSN digits into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - ssnLast4: The last 4 digits of the user's SSN. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    public func createToken(
        withSSNLast4 ssnLast4: String, completion: @escaping STPTokenCompletionBlock
    ) {
        var params: [String: Any] = [
            "pii": [
                "ssn_last_4": ssnLast4
            ]
        ]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        createToken(withParameters: params, completion: completion)
        STPTelemetryClient.shared.sendTelemetryData()
    }
}


// MARK: Payment Intents

/// STPAPIClient extensions for working with PaymentIntent objects.
extension STPAPIClient {
    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        retrievePaymentIntent(
            withClientSecret: secret,
            expand: nil,
            completion: completion)
    }

    /// Retrieves the PaymentIntent object using the given secret. - seealso: https://stripe.com/docs/api#retrieve_payment_intent
    /// - Parameters:
    ///   - secret:      The client secret of the payment intent to be retrieved. Cannot be nil.
    ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
    ///   - completion:  The callback to run with the returned PaymentIntent object, or an error.
    public func retrievePaymentIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        let endpoint: String
        var parameters: [String: Any] = [:]

        if publishableKeyIsUserKey {
            assert(
                secret.hasPrefix("pi_"),
                "`secret` format does not match expected identifer formatting.")
            endpoint = "\(APIEndpointPaymentIntents)/\(secret)"
        } else {
            assert(
                STPPaymentIntentParams.isClientSecretValid(secret),
                "`secret` format does not match expected client secret formatting.")
            let identifier = STPPaymentIntent.id(fromClientSecret: secret) ?? ""
            endpoint = "\(APIEndpointPaymentIntents)/\(identifier)"
            parameters["client_secret"] = secret
        }

        if (expand?.count ?? 0) > 0 {
            if let expand = expand {
                parameters["expand"] = expand
            }
        }

        APIRequest<STPPaymentIntent>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters
        ) { paymentIntent, _, error in
            completion(paymentIntent, error)
        }
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    public func confirmPaymentIntent(
        with paymentIntentParams: STPPaymentIntentParams,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        confirmPaymentIntent(
            with: paymentIntentParams,
            expand: nil,
            completion: completion)
    }

    /// Confirms the PaymentIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api#confirm_payment_intent
    /// @note Use the `confirmPayment:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - paymentIntentParams:  The `STPPaymentIntentParams` to pass to `/confirm`
    ///   - expand:  An array of string keys to expand on the returned PaymentIntent object. These strings should match one or more of the parameter names that are marked as expandable. - seealso: https://stripe.com/docs/api/payment_intents/object
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    public func confirmPaymentIntent(
        with paymentIntentParams: STPPaymentIntentParams,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        assert(
            STPPaymentIntentParams.isClientSecretValid(paymentIntentParams.clientSecret),
            "`paymentIntentParams.clientSecret` format does not match expected client secret formatting."
        )

        let identifier = paymentIntentParams.stripeId ?? ""
        let type = paymentIntentParams.paymentMethodParams?.rawTypeString
        STPAnalyticsClient.sharedClient.logPaymentIntentConfirmationAttempt(
            with: configuration,
            paymentMethodType: type)

        let endpoint = "\(APIEndpointPaymentIntents)/\(identifier)/confirm"

        var params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        if var sourceParamsDict = params[SourceDataHash] as? [String: Any] {
            STPTelemetryClient.shared.addTelemetryFields(toParams: &sourceParamsDict)
            sourceParamsDict = Self.paramsAddingPaymentUserAgent(sourceParamsDict)
            params[SourceDataHash] = sourceParamsDict
        }
        if var paymentMethodParamsDict = params[PaymentMethodDataHash] as? [String: Any] {
            paymentMethodParamsDict = Self.paramsAddingPaymentUserAgent(paymentMethodParamsDict)
            params[PaymentMethodDataHash] = paymentMethodParamsDict
        }
        if (expand?.count ?? 0) > 0 {
            if let expand = expand {
                params["expand"] = expand
            }
        }
        if publishableKeyIsUserKey {
            params["client_secret"] = nil
        }

        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: params
        ) { paymentIntent, _, error in
            completion(paymentIntent, error)
        }
    }

    /// Endpoint to call to indicate that the web-based challenge flow for 3DS authentication was canceled.
    func cancel3DSAuthentication(
        forPaymentIntent paymentIntentID: String,
        withSource sourceID: String,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        APIRequest<STPPaymentIntent>.post(
            with: self,
            endpoint: "\(APIEndpointPaymentIntents)/\(paymentIntentID)/source_cancel",
            parameters: [
                "source": sourceID
            ]
        ) { paymentIntent, _, responseError in
            completion(paymentIntent, responseError)
        }
    }
}

// MARK: Setup Intents

/// STPAPIClient extensions for working with SetupIntent objects.
extension STPAPIClient {
    /// Retrieves the SetupIntent object using the given secret. - seealso: https://stripe.com/docs/api/setup_intents/retrieve
    /// - Parameters:
    ///   - secret:      The client secret of the SetupIntent to be retrieved. Cannot be nil.
    ///   - completion:  The callback to run with the returned SetupIntent object, or an error.
    public func retrieveSetupIntent(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        assert(
            STPSetupIntentConfirmParams.isClientSecretValid(secret),
            "`secret` format does not match expected client secret formatting.")
        let identifier = STPSetupIntent.id(fromClientSecret: secret) ?? ""

        let endpoint = "\(APIEndpointSetupIntents)/\(identifier)"

        APIRequest<STPSetupIntent>.getWith(
            self,
            endpoint: endpoint,
            parameters: [
                "client_secret": secret
            ]
        ) { setupIntent, _, error in
            completion(setupIntent, error)
        }
    }

    /// Confirms the SetupIntent object with the provided params object.
    /// At a minimum, the params object must include the `clientSecret`.
    /// - seealso: https://stripe.com/docs/api/setup_intents/confirm
    /// @note Use the `confirmSetupIntent:withAuthenticationContext:completion:` method on `STPPaymentHandler` instead
    /// of calling this method directly. It handles any authentication necessary for you. - seealso: https://stripe.com/docs/mobile/ios/authentication
    /// - Parameters:
    ///   - setupIntentParams:    The `STPSetupIntentConfirmParams` to pass to `/confirm`
    ///   - completion:           The callback to run with the returned PaymentIntent object, or an error.
    public func confirmSetupIntent(
        with setupIntentParams: STPSetupIntentConfirmParams,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        assert(
            STPSetupIntentConfirmParams.isClientSecretValid(setupIntentParams.clientSecret),
            "`setupIntentParams.clientSecret` format does not match expected client secret formatting."
        )

        STPAnalyticsClient.sharedClient.logSetupIntentConfirmationAttempt(
            with: configuration,
            paymentMethodType: setupIntentParams.paymentMethodParams?.rawTypeString)

        let identifier = STPSetupIntent.id(fromClientSecret: setupIntentParams.clientSecret) ?? ""
        let endpoint = "\(APIEndpointSetupIntents)/\(identifier)/confirm"
        var params = STPFormEncoder.dictionary(forObject: setupIntentParams)
        if var sourceParamsDict = params[SourceDataHash] as? [String: Any] {
            STPTelemetryClient.shared.addTelemetryFields(toParams: &sourceParamsDict)
            sourceParamsDict = Self.paramsAddingPaymentUserAgent(sourceParamsDict)
            params[SourceDataHash] = sourceParamsDict
        }
        if var paymentMethodParamsDict = params[PaymentMethodDataHash] as? [String: Any] {
            paymentMethodParamsDict = Self.paramsAddingPaymentUserAgent(paymentMethodParamsDict)
            params[PaymentMethodDataHash] = paymentMethodParamsDict
        }

        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: endpoint,
            parameters: params
        ) { setupIntent, _, error in
            completion(setupIntent, error)
        }
    }

    func cancel3DSAuthentication(
        forSetupIntent setupIntentID: String,
        withSource sourceID: String,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        APIRequest<STPSetupIntent>.post(
            with: self,
            endpoint: "\(APIEndpointSetupIntents)/\(setupIntentID)/source_cancel",
            parameters: [
                "source": sourceID
            ]
        ) { setupIntent, _, responseError in
            completion(setupIntent, responseError)
        }
    }
}

// MARK: Payment Methods

/// STPAPIClient extensions for working with PaymentMethod objects.
extension STPAPIClient {
    /// Creates a PaymentMethod object with the provided params object.
    /// - seealso: https://stripe.com/docs/api/payment_methods/create
    /// - Parameters:
    ///   - paymentMethodParams:  The `STPPaymentMethodParams` to pass to `/v1/payment_methods`.  Cannot be nil.
    ///   - completion:           The callback to run with the returned PaymentMethod object, or an error.
    public func createPaymentMethod(
        with paymentMethodParams: STPPaymentMethodParams,
        completion: @escaping STPPaymentMethodCompletionBlock
    ) {
        STPAnalyticsClient.sharedClient.logPaymentMethodCreationAttempt(
            with: configuration, paymentMethodType: paymentMethodParams.rawTypeString)
        var parameters = STPFormEncoder.dictionary(forObject: paymentMethodParams)
        parameters = Self.paramsAddingPaymentUserAgent(parameters)
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: APIEndpointPaymentMethods,
            parameters: parameters
        ) { paymentMethod, _, error in
            completion(paymentMethod, error)
        }

    }
}

extension STPAPIClient {
    /// Retrieves possible BIN ranges for the 6 digit BIN prefix.
    /// - Parameter completion: The callback to run with the return STPCardBINMetadata, or an error.
    func retrieveCardBINMetadata(
        forPrefix binPrefix: String,
        withCompletion completion: @escaping (STPCardBINMetadata?, Error?) -> Void
    ) {
        assert(binPrefix.count == 6, "Requests can only be made with 6-digit binPrefixes.")
        // not adding explicit handling for above assert as endpoint will error anyway
        let params = [
            "bin_prefix": binPrefix
        ]

        let url = URL(string: CardMetadataURL)
        var request: URLRequest?
        if let url = url {
            request = configuredRequest(for: url, additionalHeaders: [:])
        }
        request?.stp_addParameters(toURL: params)
        request?.httpMethod = "GET"

        // Perform request
        if let request = request {
            urlSession.stp_performDataTask(
                with: request as URLRequest,
                completionHandler: { body, response, error in
                    guard let response = response, let body = body, error == nil else {
                        completion(nil, error)
                        return
                    }
                    APIRequest<STPCardBINMetadata>.parseResponse(
                        response,
                        body: body,
                        error: error
                    ) { object, _, parsedError in
                        completion(object, parsedError)
                    }
                })
        }
    }
}

extension STPAPIClient {
    typealias STPPaymentIntentWithPreferencesCompletionBlock = ((Result<STPPaymentIntent, Error>) -> Void)
    typealias STPSetupIntentWithPreferencesCompletionBlock = ((Result<STPSetupIntent, Error>) -> Void)

    func retrievePaymentIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPPaymentIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        guard STPPaymentIntentParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            completion(.failure(NSError.stp_clientSecretError()))
            return
        }

        parameters["client_secret"] = secret
        parameters["type"] = "payment_intent"
        parameters["expand"] = ["payment_method_preference.payment_intent.payment_method"]

        if let languageCode = Locale.current.languageCode,
           let regionCode = Locale.current.regionCode {
            parameters["locale"] = "\(languageCode)-\(regionCode)"
        }

        APIRequest<STPPaymentIntent>.getWith(self,
                                             endpoint: APIEndpointIntentWithPreferences,
                                             parameters: parameters) { paymentIntentWithPreferences, _, error in
            guard let paymentIntentWithPreferences = paymentIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(paymentIntentWithPreferences))
        }
    }

    func retrieveSetupIntentWithPreferences(
        withClientSecret secret: String,
        completion: @escaping STPSetupIntentWithPreferencesCompletionBlock
    ) {
        var parameters: [String: Any] = [:]

        guard STPSetupIntentConfirmParams.isClientSecretValid(secret) && !publishableKeyIsUserKey else {
            completion(.failure(NSError.stp_clientSecretError()))
            return
        }

        parameters["client_secret"] = secret
        parameters["type"] = "setup_intent"
        parameters["expand"] = ["payment_method_preference.setup_intent.payment_method"]

        if let languageCode = Locale.current.languageCode,
           let regionCode = Locale.current.regionCode {
            parameters["locale"] = "\(languageCode)-\(regionCode)"
        }

        APIRequest<STPSetupIntent>.getWith(self,
                                           endpoint: APIEndpointIntentWithPreferences,
                                           parameters: parameters) { setupIntentWithPreferences, _, error in

            guard let setupIntentWithPreferences = setupIntentWithPreferences else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(setupIntentWithPreferences))
        }
    }
}

private let APIEndpointToken = "tokens"
private let FileUploadURL = "https://uploads.stripe.com/v1/files"
private let APIEndpointPaymentIntents = "payment_intents"
private let APIEndpointSetupIntents = "setup_intents"
private let APIEndpointPaymentMethods = "payment_methods"
private let APIEndpointIntentWithPreferences = "elements/sessions"
private let CardMetadataURL = "https://api.stripe.com/edge-internal/card-metadata"
fileprivate let PaymentMethodDataHash = "payment_method_data"
fileprivate let SourceDataHash = "source_data"
