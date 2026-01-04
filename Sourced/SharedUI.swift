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
            .lineLimit(1)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
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
        FlowLayout(spacing: 8) {
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

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
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
        VStack(spacing: 16) {
            SizePickerRow(title: "Tops", options: MensSizes.topsOptions, selection: $mens.tops)
            SizePickerRow(title: "Bottoms", options: MensSizes.bottomsOptions, selection: $mens.bottoms)
            SizePickerRow(title: "Outerwear", options: MensSizes.outerwearOptions, selection: $mens.outerwear)
            SizePickerRow(title: "Footwear", options: MensSizes.footwearOptions, selection: $mens.footwear)
            SizePickerRow(title: "Tailoring", options: MensSizes.tailoringOptions, selection: $mens.tailoring)
            SizePickerRow(title: "Accessories", options: MensSizes.accessoriesOptions, selection: $mens.accessories)
        }
    }
}

struct SizePickerRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with title and selected value
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.black)

                    Spacer()

                    Text(selection.isEmpty ? "Select" : selection)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(selection.isEmpty ? .black.opacity(0.4) : .black)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Expandable options
            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        } label: {
                            Text(option)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(selection == option ? .white : .black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selection == option ? Color.black : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.black.opacity(0.25), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

struct SizeGridWomens: View {
    @Binding var womens: WomensSizes

    var body: some View {
        VStack(spacing: 16) {
            SizePickerRow(title: "Tops", options: WomensSizes.topsOptions, selection: $womens.tops)
            SizePickerRow(title: "Bottoms", options: WomensSizes.bottomsOptions, selection: $womens.bottoms)
            SizePickerRow(title: "Outerwear", options: WomensSizes.outerwearOptions, selection: $womens.outerwear)
            SizePickerRow(title: "Dresses", options: WomensSizes.dressesOptions, selection: $womens.dresses)
        }
    }
}

// MARK: - Utils

extension String {
    func ifEmpty(_ replacement: String) -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? replacement : self
    }
}
