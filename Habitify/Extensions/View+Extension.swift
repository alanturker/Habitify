//
//  View+Extension.swift
//  Habitify
//
//  Created by Turker Alan on 15.09.2025.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
