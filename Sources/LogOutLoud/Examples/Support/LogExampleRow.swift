#if os(iOS)

import SwiftUI

@available(iOS 16.0, *)
struct LogExampleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(Color.gray.opacity(0.35))
                .font(.system(size: 18))
        }
        .padding(.vertical, 8)
    }
}

#endif
