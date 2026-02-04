import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    var labels: [String] = []
    
    @State private var selectedIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let graphHeight = height - (labels.isEmpty ? 0 : 20)
            
            if data.count > 1 {
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal)
                let stepX = width / CGFloat(data.count - 1)
                
                ZStack {
                    // 1. Fill
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = graphHeight * (1 - CGFloat(value - minVal) / CGFloat(range))
                            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        path.addLine(to: CGPoint(x: width, y: graphHeight))
                        path.addLine(to: CGPoint(x: 0, y: graphHeight))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // 2. Stroke
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = graphHeight * (1 - CGFloat(value - minVal) / CGFloat(range))
                            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    
                    // 3. Dots & Labels (Base Layer)
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let x = stepX * CGFloat(index)
                        let y = graphHeight * (1 - CGFloat(value - minVal) / CGFloat(range))
                        
                        // Dot
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                        
                        // Label
                        if !labels.isEmpty && index < labels.count {
                            Text(labels[index].prefix(1))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(selectedIndex == index ? color : .secondary) // Highlight selected label
                                .position(x: x, y: height - 8)
                                .scaleEffect(selectedIndex == index ? 1.2 : 1.0)
                        }
                    }
                    
                    // 4. Interaction Overlay
                    if let index = selectedIndex, index < data.count {
                        let value = data[index]
                        let x = stepX * CGFloat(index)
                        let y = graphHeight * (1 - CGFloat(value - minVal) / CGFloat(range))
                        
                        // Local Focus Ring
                        Circle()
                            .stroke(color, lineWidth: 2)
                            .background(Circle().fill(.white))
                            .frame(width: 12, height: 12)
                            .position(x: x, y: y)
                            .shadow(radius: 2)
                        
                        // Tooltip
                        VStack(spacing: 2) {
                            Text(value.formatted(.currency(code: "USD")))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            if index < labels.count {
                                Text(labels[index])
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .paddingbadge(4)
                        .background(color.opacity(0.9), in: RoundedRectangle(cornerRadius: 6))
                        // Position above the point, clamped to bounds
                        .position(x: min(max(x, 40), width - 40), y: max(y - 35, 20))
                        .animation(.spring(), value: index)
                    }
                }
                .contentShape(Rectangle()) // Hit test for entire area
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let index = Int(round(value.location.x / stepX))
                            if index >= 0 && index < data.count {
                                self.selectedIndex = index
                                // Optional logic: Haptic feedback on change
                            }
                        }
                        .onEnded { _ in
                            self.selectedIndex = nil
                        }
                )
            }
        }
    }
}

extension View {
    func paddingbadge(_ value: CGFloat) -> some View {
        self.padding(.horizontal, 6).padding(.vertical, 4)
    }
}

#Preview {
    SparklineView(data: [10, 40, 20, 50, 30, 80, 20], color: .blue)
        .frame(width: 200, height: 60)
        .padding()
}
