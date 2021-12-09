//
//  STPIntentAction.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

//
//  STPIntentNextAction.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Types of next actions for `STPPaymentIntent` and `STPSetupIntent`.
/// You shouldn't need to inspect this yourself; `STPPaymentHandler` will handle any next actions for you.
@objc public enum STPIntentActionType: Int {

    /// This is an unknown action that's been added since the SDK
    /// was last updated.
    /// Update your SDK, or use the `nextAction.allResponseFields`
    /// for custom handling.
    case unknown

    /// The payment intent needs to be authorized by the user. We provide
    /// `STPPaymentHandler` to handle the url redirections necessary.
    case redirectToURL

    /// The payment intent requires additional action handled by `STPPaymentHandler`.
    case useStripeSDK

    /// Parse the string and return the correct `STPIntentActionType`,
    /// or `STPIntentActionTypeUnknown` if it's unrecognized by this version of the SDK.
    /// - Parameter string: the NSString with the `next_action.type`
    internal init(string: String) {
        switch string.lowercased() {
            case "redirect_to_url":
                self = .redirectToURL
            case "use_stripe_sdk":
                self = .useStripeSDK
            default:
                self = .unknown
        }
    }

    /// Return the string representing the provided `STPIntentActionType`.
    /// - Parameter actionType: the enum value to convert to a string
    /// - Returns: the string, or @"unknown" if this was an unrecognized type
    internal var stringValue: String {
        switch self {
            case .redirectToURL:
                return "redirect_to_url"
            case .useStripeSDK:
                return "use_stripe_sdk"
            default:
                break
        }

        // catch any unknown values here
        return "unknown"
    }
}

/// Next action details for `STPPaymentIntent` and `STPSetupIntent`.
/// This is a container for the various types that are available.
/// Check the `type` to see which one it is, and then use the related
/// property for the details necessary to handle it.
/// You cannot directly instantiate an `STPIntentAction`.
public class STPIntentAction: NSObject {

    /// The type of action needed. The value of this field determines which
    /// property of this object contains further details about the action.
    @objc public let type: STPIntentActionType

    /// The details for authorizing via URL, when `type == .redirectToURL`
    @objc public let redirectToURL: STPIntentActionRedirectToURL?

    internal let useStripeSDK: STPIntentActionUseStripeSDK?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        var props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPIntentAction.self), self),
            // Type
            "type = \(type.stringValue)",
        ]

        // omit properties that don't apply to this type
        switch type {
            case .redirectToURL:
                if let redirectToURL = redirectToURL {
                    props.append("redirectToURL = \(redirectToURL)")
                }
            case .useStripeSDK:
                if let useStripeSDK = useStripeSDK {
                    props.append("useStripeSDK = \(useStripeSDK)")
                }
            case .unknown:
                // unrecognized type, just show the original dictionary for debugging help
                props.append("allResponseFields = \(allResponseFields)")
        }

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        type: STPIntentActionType,
        redirectToURL: STPIntentActionRedirectToURL?,
        useStripeSDK: STPIntentActionUseStripeSDK?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.type = type
        self.redirectToURL = redirectToURL
        self.useStripeSDK = useStripeSDK
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentAction: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let rawType = dict["type"] as? String
        else {
            return nil
        }

        // Only set the type to a recognized value if we *also* have the expected sub-details.
        // ex: If the server said it was `.redirectToURL`, but decoding the
        // STPIntentActionRedirectToURL object fails, map type to `.unknown`
        var type = STPIntentActionType(string: rawType)
        var redirectToURL: STPIntentActionRedirectToURL?
        var useStripeSDK: STPIntentActionUseStripeSDK?

        switch type {
            case .redirectToURL:
                redirectToURL = STPIntentActionRedirectToURL.decodedObject(
                    fromAPIResponse: dict["redirect_to_url"] as? [AnyHashable: Any])
                if redirectToURL == nil {
                    type = .unknown
                }
            case .useStripeSDK:
                useStripeSDK = STPIntentActionUseStripeSDK.decodedObject(
                    fromAPIResponse: dict["use_stripe_sdk"] as? [AnyHashable: Any])
                if useStripeSDK == nil {
                    type = .unknown
                }
            default: break
        }

        return STPIntentAction(
            type: type,
            redirectToURL: redirectToURL,
            useStripeSDK: useStripeSDK,
            allResponseFields: dict) as? Self
    }

}

// MARK: - Deprecated
extension STPIntentAction {
    /// The details for authorizing via URL, when `type == STPIntentActionTypeRedirectToURL`
    /// @deprecated Use `redirectToURL` instead.
    @available(*, deprecated, message: "Use `redirectToURL` instead.", renamed: "redirectToURL")
    @objc public var authorizeWithURL: STPIntentActionRedirectToURL? {
        return redirectToURL
    }
}
