//
//  STPPaymentMethodParams.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// An object representing parameters used to create a PaymentMethod object.
/// @note To create a PaymentMethod from an Apple Pay PKPaymentToken, see `STPAPIClient createPaymentMethodWithPayment:completion:`
/// - seealso: https://stripe.com/docs/api/payment_methods/create
public class STPPaymentMethodParams: NSObject, STPFormEncodable, STPPaymentOption {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// The type of payment method.  The associated property will contain additional information (e.g. `type == STPPaymentMethodTypeCard` means `card` should also be populated).

    @objc public var type: STPPaymentMethodType {
        get {
            return STPPaymentMethod.type(from: rawTypeString ?? "")
        }
        set(newType) {
            if newType != self.type {
                rawTypeString = STPPaymentMethod.string(from: newType)
            }
        }
    }
    /// The raw underlying type string sent to the server.
    /// Generally you should use `type` instead unless you have a reason not to.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPPaymentMethodType` enum.
    /// Setting this to a value not known by the SDK causes `type` to
    /// return `STPPaymentMethodTypeUnknown`
    @objc public var rawTypeString: String?
    /// Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    @objc public var billingDetails: STPPaymentMethodBillingDetails?
    /// If this is a card PaymentMethod, this contains the user’s card details.
    @objc public var card: STPPaymentMethodCardParams?

    /// Set of key-value pairs that you can attach to the PaymentMethod. This can be useful for storing additional information about the PaymentMethod in a structured format.
    @objc public var metadata: [String: String]?

    /// Creates params for a card PaymentMethod.
    /// - Parameters:
    ///   - card:                An object containing the user's card details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc
    public convenience init(
        card: STPPaymentMethodCardParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) {
        self.init()
        self.type = .card
        self.card = card
        self.billingDetails = billingDetails
        self.metadata = metadata
    }

    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:rawTypeString)): "type",
            NSStringFromSelector(#selector(getter:billingDetails)): "billing_details",
            NSStringFromSelector(#selector(getter:card)): "card",
            NSStringFromSelector(#selector(getter:metadata)): "metadata"
        ]
    }

    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
            return STPImageLibrary.cardBrandImage(for: brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
            return STPImageLibrary.templatedBrandImage(for: brand)
        } else if type == .FPX {
            return STPImageLibrary.bankIcon()
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var label: String {
        switch type {
            case .alipay:
                return "Alipay"  //? Why aren't these localized?
            case .card:
                if let card = card {
                    let brand = STPCardValidator.brand(forNumber: card.number ?? "")
                    let brandString = STPCardBrandUtilities.stringFrom(brand)
                    return "\(brandString ?? "") \(card.last4 ?? "")"
                } else {
                    return STPCardBrandUtilities.stringFrom(.unknown) ?? ""
                }
            case .iDEAL:
                return "iDEAL"
            case .FPX:
                return "FPX"
            case .SEPADebit:
                return "SEPA Debit"
            case .bacsDebit:
                return "Bacs Debit"
            case .AUBECSDebit:
                return "AU BECS Debit"
            case .giropay:
                return "giropay"
            case .przelewy24:
                return "Przelewy24"
            case .EPS:
                return "EPS"
            case .bancontact:
                return "Bancontact"
            case .netBanking:
                return "NetBanking"
            case .OXXO:
                return "OXXO"
            case .sofort:
                return "Sofort"
            case .UPI:
                return "UPI"
            case .grabPay:
                return "GrabPay"
            case .payPal:
                return "PayPal"
            case .afterpayClearpay:
                return "Afterpay Clearpay"
            case .blik:
                return "BLIK"
            case .weChatPay:
                return "WeChat Pay"
            case .boleto:
                return "Boleto"
            case .cardPresent, .unknown:
                return STPLocalizedString("Unknown", "Default missing source type label")
            @unknown default:
                return STPLocalizedString("Unknown", "Default missing source type label")
        }
    }

    @objc public var isReusable: Bool {
        switch type {
            case .card:
                return true
            case .alipay, .AUBECSDebit, .bacsDebit, .SEPADebit, .iDEAL, .FPX, .cardPresent, .giropay,
                    .grabPay, .EPS, .przelewy24, .bancontact, .netBanking, .OXXO, .payPal, .sofort, .UPI,
                    .afterpayClearpay, .blik, .weChatPay, .boleto, // fall through
                    .unknown:
                return false
            @unknown default:
                return false
        }
    }
}

// MARK: - Legacy ObjC

@objc
extension STPPaymentMethodParams {
    /// Creates params for a card PaymentMethod.
    /// - Parameters:
    ///   - card:                An object containing the user's card details.
    ///   - billingDetails:      An object containing the user's billing details.
    ///   - metadata:            Additional information to attach to the PaymentMethod.
    @objc(paramsWithCard:billingDetails:metadata:)
    public class func paramsWith(
        card: STPPaymentMethodCardParams, billingDetails: STPPaymentMethodBillingDetails?,
        metadata: [String: String]?
    ) -> STPPaymentMethodParams {
        return STPPaymentMethodParams(
            card: card, billingDetails: billingDetails, metadata: metadata)
    }
}

extension STPPaymentMethodParams {
    convenience init(type: STPPaymentMethodType) {
        self.init()
        self.type = type
        switch type {
            case .card:
                card = STPPaymentMethodCardParams()
            case .cardPresent:
                break
            case .unknown:
                break
            default:
                break
        }
    }
}

// MARK: - PaymentSheet helpers

extension STPPaymentMethodParams {
    var paymentSheetLabel: String {
        switch type {
            case .card:
                return "••••\(card?.last4 ?? "")"
            default:
                return label
        }
    }
    
    var nonnil_billingDetails: STPPaymentMethodBillingDetails {
        guard let billingDetails = billingDetails else {
            let billingDetails = STPPaymentMethodBillingDetails()
            self.billingDetails = billingDetails
            return billingDetails
        }
        return billingDetails
    }
}
