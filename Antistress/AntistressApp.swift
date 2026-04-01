//
//  AntistressApp.swift
//  Antistress
//
//  Created by Mykhailo Mirzaiev on 30.03.2026.
//

import SwiftUI

@main
struct AntistressApp: App {
    init() {
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SubscriptionManager.shared)
        }
    }
}
