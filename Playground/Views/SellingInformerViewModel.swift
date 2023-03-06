import Foundation

enum SellingInformerState {
    struct Info {
        let title: String
        let buttonTitle: String
        let analytics: Analytics; struct Analytics { let type: String; let screen: String }
        let paywallType: PaywallType; enum PaywallType { case measurementLimit(Int); case messageStorage }
    }

    case unknown
    case userLimitsDisabled
    case lastMessageInvalidDate(Date?)
    case lastMessageType(String?)
    case profileInvalidConditions(String?, String?, Int?, Bool?, Bool?)

    case customerCancelled(Info)
    case userUnpaidCohort15to30(Info)
    case userUnpaidCohort30to90(Info)
    case userUnpaidCohort90Plus(Info)
    case userCancelled(Info)
    case measurementLimit(Info)
}

struct SellingInformerFeedMessage {
    
    let type: String?
    let sub_type: String?
    let message_type: String?
    let message_time: TimeInterval?
    
    init(message: NewsFeedMessage) {
        self.type = message.type
        self.sub_type = message.message_sub_type
        self.message_time = message.message_time
        self.message_type = message.message_type
    }
    
    init(type: String? = nil, sub_type: String? = nil, message_type: String? = nil, message_time: TimeInterval? = nil) {
        self.type = type
        self.sub_type = sub_type
        self.message_type = message_type
        self.message_time = message_time
    }
    
}

protocol SellingInformerViewModel {

    var state: SellingInformerState { get }

    func update(message: SellingInformerFeedMessage)

}

/// Model implementing conditions for showing informer
/// https://welltory.atlassian.net/wiki/spaces/RD/pages/4066148353
final class SellingInformerViewModelImpl: SellingInformerViewModel {

    struct Constants {

        static let userUnpaidCohortDayTitle_15_30 = tr("SellingInformerView_Title_user_unpaid_15_30")
        static let userUnpaidCohortDayButtonTitle_15_30 = tr("SellingInformerView_ButtonTitle_user_unpaid_15_30")

        static let userUnpaidCohortDayTitle_30_90 = tr("SellingInformerView_Title_user_unpaid_30_90")
        static let userUnpaidCohortDayButtonTitle_30_90 = tr("SellingInformerView_ButtonTitle_user_unpaid_30_90")

        static let userUnpaidCohortDayTitle_90 = tr("SellingInformerView_Title_user_unpaid_90")
        static let userUnpaidCohortDayButtonTitle_90 = tr("SellingInformerView_ButtonTitle_user_unpaid_90")

        static let customerCancelledTitle = tr("SellingInformerView_Title_customer_cancelled")
        static let customerCancelledButtonTitle = tr("SellingInformerView_ButtonTitle_customer_cancelled")

        static let userCancelledTitle = tr("SellingInformerView_Title_user_canceled")
        static let userCancelledButtonTitle = tr("SellingInformerView_ButtonTitle_user_canceled")
        
        static let userMeasurementLimitTitle = tr("SellingInformerView_Title_user_measuremenet_limit")
        static let userMeasurementLimitButtonTitle = tr("SellingInformerView_ButtonTitle_user_measuremenet_limit")

        private static func tr(_ key: String) -> String {
            let format = Bundle.main.localizedString(forKey: key, value: nil, table: "SellingInformerView")
            return String(format: format, locale: Locale.current)
        }
    }

    var userProfileService: WTUserProfileService!

    private var lastDisplayedMessage: SellingInformerFeedMessage?

    var state: SellingInformerState {
        guard let profile = userProfileService.profile else { return .unknown }
        let daysGap = userProfileService.createdAt?.amountOfDays(to: Date()) ?? 0
        let userState = profile.user_state
        let billingStatus = profile.billing_status
        let userLimitsEnable = userProfileService.userLimitsEnable?.boolValue
        let isFakeTrial = profile.is_fake_trial
        let isAwUser = profile.is_aw_user?.boolValue
        // DEBUG
        if ProcessInfo.processInfo.environment["SELLING_INFORMER"] != nil {
            let env = ProcessInfo.processInfo.environment
            let userLimitsEnable = Bool(env["SELLING_INFORMER_USER_LIMITS_ENABLE"] ?? "false") ?? false
            let daysGap = Int(env["SELLING_INFORMER_DAYS"] ?? "0") ?? 0
            let userState = env["SELLING_INFORMER_USER_STATE"]
            let billingStatus = env["SELLING_INFORMER_BILLING_STATUS"]
            return self.getState(userLimitsEnable: userLimitsEnable,
                                 message: lastDisplayedMessage,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: nil,
                                 isAwUser: nil,
                                 cohortDay: daysGap)
        }
        // END
        return self.getState(userLimitsEnable: userLimitsEnable,
                             message: lastDisplayedMessage,
                             billingStatus: billingStatus,
                             userState: userState,
                             isFakeTrial: isFakeTrial,
                             isAwUser: isAwUser,
                             cohortDay: daysGap)
    }

    func update(message: SellingInformerFeedMessage) {
        self.lastDisplayedMessage = message
    }

    // MARK: Internal

    func getState(userLimitsEnable: Bool?,
                  message: SellingInformerFeedMessage?,
                  billingStatus: String?,
                  userState: String?,
                  isFakeTrial: Bool?,
                  isAwUser: Bool?,
                  cohortDay: Int) -> SellingInformerState {
        let messageStorageAnalytics = SellingInformerState.Info.Analytics(type: "message_storage", screen: "banner_message_storage")
        let messageStoragePaywallType = SellingInformerState.Info.PaywallType.messageStorage
        return .userUnpaidCohort15to30(.init(title: Constants.userUnpaidCohortDayTitle_15_30,
                                             buttonTitle: Constants.userUnpaidCohortDayButtonTitle_15_30,
                                             analytics: messageStorageAnalytics,
                                             paywallType: messageStoragePaywallType))
        // START: User condition
        guard userLimitsEnable == true else {
            return .userLimitsDisabled
        }
        // END
        // START: Message condition
        guard let msgTime = message?.message_time else {
            return .lastMessageInvalidDate(nil)
        }
        let date = Date.init(timeIntervalSince1970: msgTime)
        guard !date.isInToday && !date.isInYesterday else {
            return .lastMessageInvalidDate(date)
        }
        guard message?.type != "upgrade" && message?.type != "upgrade_message_expired" else {
            return .lastMessageType([message?.type, message?.sub_type].compactMap { $0 }.joined(separator: " | "))
        }
        // END
        // START: Message storage conditions
//        let messageStorageAnalytics = SellingInformerState.Info.Analytics(type: "message_storage", screen: "banner_message_storage")
//        let messageStoragePaywallType = SellingInformerState.Info.PaywallType.messageStorage
        switch (userState, billingStatus) {
        case ("customer", "cancelled"):
            return .customerCancelled(.init(title: Constants.customerCancelledTitle,
                                            buttonTitle: Constants.customerCancelledButtonTitle,
                                            analytics: messageStorageAnalytics,
                                            paywallType: messageStoragePaywallType))
        case ("user", "unpaid"):
            switch cohortDay {
            case 15..<30:
                return .userUnpaidCohort15to30(.init(title: Constants.userUnpaidCohortDayTitle_15_30,
                                                     buttonTitle: Constants.userUnpaidCohortDayButtonTitle_15_30,
                                                     analytics: messageStorageAnalytics,
                                                     paywallType: messageStoragePaywallType))
            case 30..<90:
                return .userUnpaidCohort30to90(.init(title: Constants.userUnpaidCohortDayTitle_30_90,
                                                     buttonTitle: Constants.userUnpaidCohortDayButtonTitle_30_90,
                                                     analytics: messageStorageAnalytics,
                                                     paywallType: messageStoragePaywallType))
            case _ where cohortDay >= 90:
                return .userUnpaidCohort90Plus(.init(title: Constants.userUnpaidCohortDayTitle_90,
                                                     buttonTitle: Constants.userUnpaidCohortDayButtonTitle_90,
                                                     analytics: messageStorageAnalytics,
                                                     paywallType: messageStoragePaywallType))
            default:
                break
            }
        case ("user", "cancelled"):
            return .userCancelled(.init(title: Constants.userCancelledTitle,
                                            buttonTitle: Constants.userCancelledButtonTitle,
                                            analytics: messageStorageAnalytics,
                                            paywallType: messageStoragePaywallType))
        default:
            break
        }
        // END
        // START: Measurement conditions
        if userState == "user", isFakeTrial != true, isAwUser == true,  5 <= cohortDay && cohortDay < 14 {
            let measurementLimitAnalytics = SellingInformerState.Info.Analytics(type: "measurement_limit", screen: "banner_measurement_limit")
            let measurementLimitPaywallType = SellingInformerState.Info.PaywallType.measurementLimit(352)
            return .measurementLimit(.init(title: Constants.userMeasurementLimitTitle,
                                            buttonTitle: Constants.userMeasurementLimitButtonTitle,
                                            analytics: measurementLimitAnalytics,
                                            paywallType: measurementLimitPaywallType))
        }
        // END

        return .profileInvalidConditions(userState, billingStatus, cohortDay, isFakeTrial, isAwUser)
    }

}

extension SellingInformerState.Info: Equatable {}
extension SellingInformerState.Info.PaywallType: Equatable {}
extension SellingInformerState.Info.Analytics: Equatable {}
