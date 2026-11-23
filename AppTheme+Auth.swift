//
//  AppTheme+Auth.swift
//  StudyVerse
//
//  Branch: Welcome-View
//  Owner: Maira Zaman
//
//  Extra AppTheme values needed by the Authentication / Profile screens.
//  Kept in this separate file so Fatima's AppTheme.swift stays unchanged.
//  Values from the Figma prototype; used by PrimaryButton, SecondaryButton,
//  InputField and the yellow chips.
//

import SwiftUI

extension AppTheme {
    static let chipYellow: Color     = Color(hex: "#FFF0A8")   // XP / coin chips, logo star
    static let inputBorder: Color    = navEnd                  // #b8def1 blue
    static let buttonHeight: CGFloat = 50
    static let buttonRadius: CGFloat = 16
    static let inputHeight: CGFloat  = 48
    static let inputRadius: CGFloat  = 14
}
