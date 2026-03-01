import SwiftUI

struct SpotDetailView: View {
    let spot: SpotData
    let detail: SpotDetail?
    let isLoading: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Photo carousel
                if let detail, !detail.photoUrls.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detail.photoUrls, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(.quaternary)
                                    }
                                    .frame(width: 280, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                } else if let photoUrl = spot.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(.quaternary)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(spot.name)
                        .font(.title3.weight(.bold))

                    HStack(spacing: 8) {
                        if let rating = detail?.rating ?? spot.rating {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                Text(String(format: "%.1f", rating))
                                if let count = detail?.reviewCount {
                                    Text("(\(Int(count)))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline)
                        }

                        if let price = detail?.priceLevel ?? spot.priceLevel {
                            Text(String(repeating: "$", count: Int(price)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let isOpen = detail?.isOpenNow {
                            Text(isOpen ? "Open" : "Closed")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isOpen ? .green : .red)
                        }
                    }

                    Text(detail?.address ?? spot.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading details...")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }

                if let detail {
                    // Perplexity summary
                    if let summary = detail.perplexitySummary {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("The lowdown", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                    }

                    // Editorial summary
                    if let editorial = detail.editorialSummary {
                        Text(editorial)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                    }

                    // Quick actions
                    HStack(spacing: 12) {
                        if let phone = detail.phone {
                            if let phoneUrl = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                Link(destination: phoneUrl) {
                                    Label("Call", systemImage: "phone.fill")
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(.regularMaterial, in: Capsule())
                                }
                            }
                        }

                        if let website = detail.website, let webUrl = URL(string: website) {
                            Link(destination: webUrl) {
                                Label("Website", systemImage: "safari.fill")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.regularMaterial, in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Hours
                    if let hours = detail.hours, !hours.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hours")
                                .font(.subheadline.weight(.semibold))
                            ForEach(hours, id: \.self) { line in
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Reviews
                    if let reviews = detail.reviews, !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reviews")
                                .font(.subheadline.weight(.semibold))

                            ForEach(reviews) { review in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        ForEach(0..<Int(review.rating), id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                        Spacer()
                                        Text(review.time)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Text(review.text)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(4)
                                }
                                .padding(10)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}
