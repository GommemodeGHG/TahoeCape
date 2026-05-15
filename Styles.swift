import SwiftUI

struct TahoeColors {
    static let primary = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let accent = Color(red: 0.9, green: 0.3, blue: 0.8)
    static let glassBackground = Color.white.opacity(0.1)
    
    static let auroraGradient = LinearGradient(
        colors: [.blue, .purple, .pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}

struct TahoeButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isHovering {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TahoeColors.auroraGradient.opacity(0.2))
                            .blur(radius: 4)
                    }
                    RoundedRectangle(cornerRadius: 12)
                        .fill(configuration.isPressed ? Color.white.opacity(0.1) : Color.white.opacity(0.15))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovering ? TahoeColors.primary.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

struct CursorCard: View {
    let cursor: Cursor
    let name: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                if let rep = cursor.representations["1x"], let data = rep.data, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "cursorarrow")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Text(name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Text("\(cursor.representations.count) Sizes")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(width: 120, height: 160)
        .liquidGlass()
    }
}
