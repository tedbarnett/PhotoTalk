//
//  EnvironmentManager.swift
//  MyPhotoReviewer-Development
//
//  Created by Prem Pratap Singh on 27/04/23.
//

import Foundation

/**
 EnvironmentManager is a singleton class that provides information about current run time
 environment (`dev` or `prod`) of the app. This environment is very crucial as it helps in pointing
 to the right backend and other APIs.
 */
class EnvironmentManager {
    
    // MARK: - Public properties
    
    /// Returns singleton instance
    public static var shared: EnvironmentManager {
        return self.instance
    }
    
    /// Current active environment of the app
    var currentEnvironment: Environment = .prod
    
    // MARK: - Private properties
    
    private static let instance = EnvironmentManager()
    private let buildEnvKey = "com.BarnettLabs.PhotoReview.Environment"
    private let buildEnvValueDev = "dev"
    private let buildEnvValueProd = "dev"
    
    
    // MARK: Initilizer

    private init() {
        self.configureEnvironment()
    }
    
    /// Sets application run environment based on the launch key parameter
    /// Environment value determines the backend service endpoint URLs and other run environment specific details
    private func configureEnvironment() {
        guard let launchEnvKey = ProcessInfo.processInfo.environment[self.buildEnvKey] else {
            self.currentEnvironment = .prod
            return
        }

        switch launchEnvKey {
        case buildEnvValueDev: self.currentEnvironment = .dev
        case buildEnvValueProd: self.currentEnvironment = .prod
        default: self.currentEnvironment = .prod
        }
    }
}

/**
 Environment enum provides environment specific details
 */
enum Environment {
    case prod
    case dev
    
    // MARK: Public properties
    
    var name: String {
        switch self {
        case .prod: return "prod"
        case .dev: return "dev"
        }
    }
}
