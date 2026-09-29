import SwiftUI
import AeryCore

@main
struct AeryAirApp: App {
    var body: some Scene {
        WindowGroup("Aery Air") { ContentView() }
            .defaultSize(width: 980, height: 680)
    }
}

struct ContentView: View {
    @State private var design = GliderDesign()

    private var assessment: FlightAssessment { FlightAssessment(design: design) }

    var body: some View {
        NavigationSplitView {
            Form {
                Section("Design") {
                    TextField("Name", text: $design.name)
                    numberField("Wingspan", value: $design.wingspan, unit: "m")
                    numberField("Wing chord", value: $design.wingChord, unit: "m")
                    numberField("Mass", value: $design.mass, unit: "kg")
                }
                Section("Stability") {
                    numberField("Horizontal tail area", value: $design.horizontalTailArea, unit: "m²")
                    numberField("Tail moment arm", value: $design.tailMomentArm, unit: "m")
                    numberField("Center of gravity", value: $design.centerOfGravity, unit: "chord")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Aery Air")
            .frame(minWidth: 290)
        } detail: {
            VStack(spacing: 22) {
                PlanformView(design: design)
                    .frame(maxHeight: 290)
                HStack(spacing: 14) {
                    metric("Wing area", String(format: "%.3f m²", design.wingArea))
                    metric("Aspect ratio", String(format: "%.1f", assessment.aspectRatio))
                    metric("Wing loading", String(format: "%.1f N/m²", assessment.wingLoading))
                    metric("Launch speed", String(format: "%.1f m/s", assessment.estimatedLaunchSpeed))
                }
                AssessmentView(assessment: assessment)
                Spacer()
            }
            .padding(28)
            .navigationTitle(design.name)
        }
    }

    @ViewBuilder
    private func numberField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            TextField(label, value: value, format: .number.precision(.fractionLength(3)))
            Text(unit).foregroundStyle(.secondary).frame(width: 38, alignment: .leading)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.monospacedDigit()).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct AssessmentView: View {
    let assessment: FlightAssessment
    private var color: Color {
        switch assessment.verdict {
        case .ready: return .green
        case .caution: return .orange
        case .unsafe: return .red
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(assessment.verdict.rawValue, systemImage: "paperplane.fill")
                .font(.headline).foregroundStyle(color)
            ForEach(assessment.messages, id: \.self) { Text("• \($0)") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PlanformView: View {
    let design: GliderDesign
    var body: some View {
        Canvas { context, size in
            let span = min(size.width * 0.78, size.height * 0.72)
            let chord = max(18, span * design.wingChord / max(design.wingspan, 0.01))
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let wing = CGRect(x: center.x - span / 2, y: center.y - chord / 2, width: span, height: chord)
            context.fill(Path(roundedRect: wing, cornerRadius: 5), with: .color(.blue.opacity(0.72)))
            let boomEnd = CGPoint(x: wing.maxX + span * 0.24, y: center.y)
            var boom = Path(); boom.move(to: CGPoint(x: wing.maxX, y: center.y)); boom.addLine(to: boomEnd)
            context.stroke(boom, with: .color(.secondary), lineWidth: 5)
            let tailWidth = max(22, chord * design.horizontalTailArea / max(design.wingArea, 0.001) * 3)
            let tail = CGRect(x: boomEnd.x - tailWidth / 2, y: center.y - chord * 0.34, width: tailWidth, height: chord * 0.68)
            context.fill(Path(roundedRect: tail, cornerRadius: 4), with: .color(.orange.opacity(0.78)))
            let cg = CGPoint(x: wing.minX + wing.width * design.centerOfGravity, y: center.y)
            context.fill(Path(ellipseIn: CGRect(x: cg.x - 6, y: cg.y - 6, width: 12, height: 12)), with: .color(.red))
        }
        .background(.gray.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Top view of the current glider design")
    }
}
