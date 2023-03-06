import XCTest
@testable import Playground

class SellingInformerViewModelImplTests: XCTestCase {
    var model: SellingInformerViewModelImpl { SellingInformerViewModelImpl() }
        
    func test_UserLimitsDisabled() {
        // Given
        let userLimitsEnable = false
        let message: SellingInformerFeedMessage? = nil
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .userLimitsDisabled = state else {
            XCTFail(String(describing: state))
            return
        }
    }
    
    // MARK: - Measurement Limits
    
    // MARK: Messages
    
    func test_InvalidDateWithNilDate() {
        // Given
        let userLimitsEnable = true
        let message: SellingInformerFeedMessage? = nil
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .lastMessageInvalidDate(nil) = state else {
            XCTFail(String(describing: state))
            return
        }
    }
    
    func test_InvalidDateToday() {
        // Given
        let userLimitsEnable = true
        let date = Date()
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .lastMessageInvalidDate(_) = state else {
            XCTFail("Got \(String(describing: state)), expected \(date.description)")
            return
        }
    }
    
    func test_InvalidDateYesterday() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .lastMessageInvalidDate(_) = state else {
            XCTFail("Got \(String(describing: state)), expected \(date.description)")
            return
        }
    }
    
    func test_ValidDate() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .profileInvalidConditions(userState, billingStatus, cohortDay, isFakeTrial, isAwUser) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    func test_Upgrade() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "upgrade", sub_type: "upgrade_message_expired",
                                                         message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = nil
        let userState: String? = nil
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        guard case .lastMessageType("upgrade | upgrade_message_expired") = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }

    // MARK: Customer
    
    func test_CustomerUpaid() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = "cancelled"
        let userState: String? = "customer"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.customerCancelledTitle,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.customerCancelledButtonTitle,
                                             analytics: SellingInformerState.Info.Analytics(type: "message_storage",
                                                                                            screen: "banner_message_storage"),
                                             paywallType: .messageStorage)
        guard case .customerCancelled(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    // MARK: User
    
    func test_UserCancelled() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = "cancelled"
        let userState: String? = "user"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 0
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.userCancelledTitle,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.userCancelledButtonTitle,
                                             analytics: SellingInformerState.Info.Analytics(type: "message_storage",
                                                                                            screen: "banner_message_storage"),
                                             paywallType: .messageStorage)
        guard case .userCancelled(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    func test_UserUnpaid15to30() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = "unpaid"
        let userState: String? = "user"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 15
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayTitle_15_30,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayButtonTitle_15_30,
                                             analytics: SellingInformerState.Info.Analytics(type: "message_storage",
                                                                                            screen: "banner_message_storage"),
                                             paywallType: .messageStorage)
        guard case .userUnpaidCohort15to30(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    func test_UserUnpaid30to90() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = "unpaid"
        let userState: String? = "user"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 30
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayTitle_30_90,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayButtonTitle_30_90,
                                             analytics: SellingInformerState.Info.Analytics(type: "message_storage",
                                                                                            screen: "banner_message_storage"),
                                             paywallType: .messageStorage)
        guard case .userUnpaidCohort30to90(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    func test_UserUnpaid90Plus() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = "unpaid"
        let userState: String? = "user"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = nil
        let cohortDay = 90
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayTitle_90,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.userUnpaidCohortDayButtonTitle_90,
                                             analytics: SellingInformerState.Info.Analytics(type: "message_storage",
                                                                                            screen: "banner_message_storage"),
                                             paywallType: .messageStorage)
        guard case .userUnpaidCohort90Plus(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
    // MARK: - Message storage
    
    func test_AwUser_NoTrial_Day5() {
        // Given
        let userLimitsEnable = true
        let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let message: SellingInformerFeedMessage? = .init(type: "test", sub_type: "test", message_type: "test",
                                                         message_time: date.timeIntervalSince1970)
        let billingStatus: String? = nil
        let userState: String? = "user"
        let isFakeTrial: Bool? = nil
        let isAwUser: Bool? = true
        let cohortDay = 5
        
        // When
        let state = model.getState(userLimitsEnable: userLimitsEnable,
                                 message: message,
                                 billingStatus: billingStatus,
                                 userState: userState,
                                 isFakeTrial: isFakeTrial,
                                 isAwUser: isAwUser,
                                 cohortDay: cohortDay)
        
        // Then
        let info = SellingInformerState.Info(title: SellingInformerViewModelImpl.Constants.userMeasurementLimitTitle,
                                             buttonTitle: SellingInformerViewModelImpl.Constants.userMeasurementLimitButtonTitle,
                                             analytics: SellingInformerState.Info.Analytics(type: "measurement_limit",
                                                                                            screen: "banner_measurement_limit"),
                                             paywallType: .measurementLimit(352))
        guard case .measurementLimit(info) = state else {
            XCTFail("Got \(String(describing: state))")
            return
        }
    }
    
}

