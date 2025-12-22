//
//  FeedScreen.swift
//  Sourced
//

import SwiftUI

struct ThriftItem: Identifiable {
    let id: Int
    let title: String
    let brand: String
    let price: String
    let size: String
    let tags: [String]
    let source: String
}

struct PersonalizedFeedScreen: View {
    @EnvironmentObject var flow: OnboardingFlow
    @State private var showLogoutConfirmation = false

    let items: [ThriftItem] = [
        ThriftItem(
            id: 1,
            title: "Vintage Levi’s 501 Straight Leg",
            brand: "Levi’s",
            price: "$48",
            size: "W32 L30",
            tags: ["Vintage denim", "Light wash"],
            source: "Poshmark"
        ),
        ThriftItem(
            id: 2,
            title: "Boxy black wool coat",
            brand: "COS",
            price: "$120",
            size: "M",
            tags: ["Minimal", "Outerwear"],
            source: "eBay"
        ),
        ThriftItem(
            id: 3,
            title: "White leather low-top sneakers",
            brand: "Nike",
            price: "$65",
            size: "10.5",
            tags: ["Clean classics"],
            source: "Grailed"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("For you")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                Button {
                    showLogoutConfirmation = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                }
                .confirmationDialog("Account", isPresented: $showLogoutConfirmation) {
                    Button("Log Out", role: .destructive) {
                        flow.logout()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Text("Based on your vibe, sizing, and favorite brands.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.black.opacity(0.65))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(items) { item in
                        ThriftItemCard(item: item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }

            VStack(spacing: 12) {
                Button {
                    // TODO: navigate to alerts config
                } label: {
                    Text("Set alerts")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    // TODO: show saved items view
                } label: {
                    Text("View saved items")
                        .foregroundColor(.black.opacity(0.85))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct ThriftItemCard: View {
    let item: ThriftItem
    @State private var isSaved: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.06))
                .frame(height: 160)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Text("Sourced from \(item.source)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                            Spacer()
                        }
                        .padding(10)
                    }
                )

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.brand.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))

                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)

                    HStack(spacing: 10) {
                        Text(item.price)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(item.size)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                    }

                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }
                }

                Spacer()

                Button {
                    isSaved.toggle()
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
