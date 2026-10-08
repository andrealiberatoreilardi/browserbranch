import SwiftUI

struct CopyLinkButton: View {
    var height: CGFloat = 98
    let onCopy: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 32, weight: .regular))
                        .frame(width: 48, height: 48)

                    Text("\\")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: 6, y: -6)
                        .accessibilityHidden(true)
                }

                Text("Copia link")
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(width: 90, height: height)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHovered ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.055))
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Copia link")
        .accessibilityHint("Copia l’indirizzo completo negli appunti")
        .help(Text(verbatim: "Copia link (\\)"))
    }
}
