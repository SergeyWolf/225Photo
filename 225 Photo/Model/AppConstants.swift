//
//  AppConstants.swift
//  225 Photo
//
//  Created by Сергей on 08.12.2025.
//

import Foundation

enum AppConstants {
    
    enum MinCounToken {
        static let token = 2
    }
    
    enum Bundle {
        static let bundle = "com.ole.225ph0t0"
    }
    
    enum Apphud {
        static let apiKey = "app_BJdDvqQZy8ChhhSwemyXhryGP8gygF"
    }

    enum Support {
        /// Email для техподдержки
        static let email = "omatokitawatashi@gmail.com"

        /// Форма поддержки (Google Forms)
        static let supportFormURL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLScExaDaRrLm71wc08oqr1MucLs4rgTEIlZCUcKxYLhmg3rO_g/viewform?usp=publish-editor")!

        /// Ссылка на приложение в App Store
        static let appStoreURL = URL(string: "https://apps.apple.com/us/app/dreamrender-studio/id6755883330")!
        
        static let openStoreURL = URL(string: "https://itunes.apple.com/app/id6755883330?action=write-review")
        
    }

    enum Legal {
        /// Политика конфиденциальности
        static let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/1Rc9jayAfXiIHdEkqFP4y7CSSwrsn_rV33XCk4IECeWk/edit?usp=sharing")!

        /// Условия использования
        static let termsOfUseURL = URL(string: "https://docs.google.com/document/d/1jrFLMEd8bevHO7nwpG1U4Uz74ovXM4BCKd3NPQ8ZMXM/edit?usp=sharing")!
    }
}
