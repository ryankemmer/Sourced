//
//  SharedUI.swift
//  Sourced
//

import SwiftUI

// MARK: - Shell

struct OnboardingShell<Content: View>: View {
    let title: String?
    let subtitle: String?
    let showBack: Bool
    let backAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        showBack: Bool = false,
        backAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBack = showBack
        self.backAction = backAction
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button(action: { backAction?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                } else {
                    Spacer().frame(width: 24)
                }

                Spacer()

                Text("Sourced")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black.opacity(0.75))

                Spacer().frame(width: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            if let title {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.65))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }

            ScrollView {
                VStack(spacing: 20) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.top, title == nil ? 40 : 24)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.65 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Small Components

struct SourcedMonoLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.9), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 10)

            Text("S")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
        }
    }
}

struct TagChip: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .black)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct OnboardingTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundColor(.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1)
            )
            .accentColor(.black)
    }
}

struct SectionHeader<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.black)

            content()
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.black.opacity(0.65))
        }
    }
}

// Chips layout

struct WrapChips: View {
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 200), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { item in
                let isSelected = selected.contains(item)
                Button {
                    if isSelected {
                        selected.remove(item)
                    } else {
                        selected.insert(item)
                    }
                } label: {
                    TagChip(text: item, isSelected: isSelected)
                }
            }
        }
    }
}


// Size fields

struct SizeField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))

            TextField(placeholder, text: $text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
        }
    }
}

struct SizeGridMens: View {
    @Binding var mens: MensSizes

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                SizeField(title: "Shirt", placeholder: "M / 40", text: $mens.shirt)
                SizeField(title: "Pants", placeholder: "32x32", text: $mens.pants)
            }
            HStack {
                SizeField(title: "Jacket", placeholder: "40R", text: $mens.jacket)
                SizeField(title: "Shoes", placeholder: "10.5", text: $mens.shoes)
            }
        }
    }
}

struct SizeGridWomens: View {
    @Binding var womens: WomensSizes

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                SizeField(title: "Shirt", placeholder: "S / 4", text: $womens.shirt)
                SizeField(title: "Pants", placeholder: "26 / 2", text: $womens.pants)
            }
            HStack {
                SizeField(title: "Jacket", placeholder: "S / 4", text: $womens.jacket)
                SizeField(title: "Sweaters", placeholder: "S / M", text: $womens.sweaters)
            }
            HStack {
                SizeField(title: "Shoes", placeholder: "7.5", text: $womens.shoes)
                SizeField(title: "Handbags", placeholder: "Med / Lg", text: $womens.handbags)
            }
            HStack {
                SizeField(title: "Dress", placeholder: "4 / S", text: $womens.dress)
                SizeField(title: "Skirt", placeholder: "26 / 2", text: $womens.skirt)
            }
        }
    }
}

// MARK: - Utils

extension String {
    func ifEmpty(_ replacement: String) -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? replacement : self
    }
}
