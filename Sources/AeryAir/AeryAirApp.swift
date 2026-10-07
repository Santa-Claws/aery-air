import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AeryCore

@main
struct AeryAirApp: App {
    var body: some Scene {
        WindowGroup("Aery") { ContentView() }
            .defaultSize(width: 760, height: 610)
            .windowResizability(.contentMinSize)
    }
}

private enum AeryTab: String, CaseIterable, Identifiable { case main = "Main", wing = "Wing", stabilizer = "Stabilizer", verticalTail = "Vertical Tail", information = "Information"; var id: String { rawValue } }

struct ContentView: View {
    @State private var design = GliderDesign()
    @State private var tab: AeryTab = .main
    @State private var analysis = FlightAssessment(design: GliderDesign())
    @State private var status = "Displays the current part of the glider"
    @State private var showConfiguration = false

    var body: some View {
        VStack(spacing: 0) {
            menuBar
            Picker("", selection: $tab) { ForEach(AeryTab.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented).padding(.horizontal, 12).padding(.top, 8)
            GroupBox {
                HStack(alignment: .top, spacing: 10) { controls; Divider(); statistics }
                    .padding(8)
            }.padding(10)
            GroupBox { PlanView(design: design, tab: tab).frame(maxWidth: .infinity, maxHeight: .infinity).padding(6) }
                .padding(.horizontal, 10)
            HStack { Text(status).font(.system(size: 12, weight: .semibold)); Spacer(); Text("Aery32 compatible").font(.caption).foregroundStyle(.secondary) }
                .padding(.horizontal, 14).padding(.vertical, 7).background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 690, minHeight: 540)
        .sheet(isPresented: $showConfiguration) { ConfigurationView(configuration: $design.configuration) }
    }

    private var menuBar: some View {
        HStack(spacing: 6) {
            Menu("File") {
                Button("New Design") { design = GliderDesign(); analyze(); status = "New Design" }
                Button("Open Design…") { open() }
                Button("Save Design As…") { save() }
                Divider()
                Button("Edit Configuration…") { showConfiguration = true }
            }
            Menu("Analyses") { Button("Update Statistics") { analyze(); status = "Statistics updated" }; Button("Will it Fly?", action: analyze).keyboardShortcut("3") }
            Spacer()
            Text("Aery: \(design.name)").font(.headline).lineLimit(1)
            Spacer()
        }.padding(.horizontal, 12).padding(.vertical, 5).background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder private var controls: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch tab {
            case .main:
                AeryBar(label: "Fuselage Length (cm)", value: $design.fuselageLength, range: 20...design.configuration.maximumFuselageLength, help: "Change the overall fuselage length", status: $status)
                AeryBar(label: "Wing Location (cm)", value: $design.wingLocation, range: 0...design.fuselageLength, help: "Change the location of root leading edge on fuselage", status: $status)
                AeryBar(label: "Stabilizer Location (cm)", value: $design.stabilizerLocation, range: 0...design.fuselageLength, help: "Change the stabilizer location", status: $status)
                AeryBar(label: "Vertical Tail Location (cm)", value: $design.verticalTailLocation, range: 0...design.fuselageLength, help: "Change the vertical tail location", status: $status)
                AeryBar(label: "Nose Mass (g)", value: $design.noseMass, range: 0...design.configuration.maximumNoseMass, help: "Change the amount of weight at the nose", status: $status)
            case .wing: surfaceControls($design.wing, prefix: "Wing", includesVelocity: true)
            case .stabilizer: surfaceControls($design.stabilizer, prefix: "Stabilizer", includesVelocity: false)
            case .verticalTail: surfaceControls($design.verticalTail, prefix: "Vertical Tail", includesVelocity: false)
            case .information:
                TextField("Glider Name", text: $design.name).textFieldStyle(.roundedBorder)
                Text("Type the name of your glider here").font(.caption)
                Button("Will it Fly?", action: analyze).buttonStyle(.borderedProminent)
            }
        }.frame(width: 385, alignment: .topLeading)
    }

    @ViewBuilder private var statistics: some View {
        VStack(alignment: .leading, spacing: 4) {
            if tab == .information {
                Text("[Analyze]").font(.headline)
                ScrollView { Text(analysis.messages.joined(separator: "\n\n")).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
            } else {
                Text("Glider CG     \(design.centerOfGravity, specifier: "%06.2f") cm")
                Text("Glider Mass   \(design.estimatedMass, specifier: "%06.2f") g")
                Text("Wing Loading  \(analysis.wingLoading, specifier: "%0.3f") g/cm²")
                Divider().padding(.vertical, 3)
                Text("Wing AC = \(design.wingLocation + design.wing.rootChord / 4, specifier: "%0.2f") cm")
                Text("Neutral Point = \(analysis.neutralPoint, specifier: "%0.2f") cm")
                Text("Stall velocity = \(analysis.stallVelocity, specifier: "%0.1f") km/hr")
                Text(analysis.flies ? "It will fly!" : "Needs adjustment").fontWeight(.bold).foregroundStyle(analysis.flies ? .green : .red)
            }
            Spacer()
        }.font(.system(.body, design: .monospaced)).frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
    }

    private func surfaceControls(_ surface: Binding<Surface>, prefix: String, includesVelocity: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            AeryBar(label: prefix == "Vertical Tail" ? "Height (cm)" : "Span (cm)", value: surface.span, range: 1...200, help: "Change the \(prefix.lowercased()) span", status: $status)
            AeryBar(label: "Root Chord (cm)", value: surface.rootChord, range: 1...30, help: "Change the \(prefix.lowercased()) root chord", status: $status)
            AeryBar(label: "Taper Ratio", value: surface.taperRatio, range: 0.2...1, help: "Change the \(prefix.lowercased()) taper ratio", status: $status)
            AeryBar(label: "Leading Edge Sweep Angle", value: surface.sweepAngle, range: 0...45, help: "Change the \(prefix.lowercased()) sweep angle", status: $status)
            Picker("Sweep", selection: surface.sweepType) { ForEach(SweepType.allCases, id: \.self) { Text($0.title).tag($0) } }.labelsHidden().frame(maxWidth: .infinity)
            if includesVelocity { AeryBar(label: "Velocity (km/hr)", value: $design.throwingVelocity, range: 5...60, help: "Change the velocity at which the glider will be thrown", status: $status) }
        }
    }

    private func analyze() { analysis = FlightAssessment(design: design); tab = .information; status = analysis.flies ? "It will fly!" : "Review the analysis recommendations" }
    private func open() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.init(filenameExtension: "ae")!]
        guard panel.runModal() == .OK, let url = panel.url, let text = try? String(contentsOf: url, encoding: .utf8), let opened = AeryFile.decode(text) else { return }
        design = opened; analysis = FlightAssessment(design: design); status = "File Opened"
    }
    private func save() {
        let panel = NSSavePanel(); panel.allowedContentTypes = [.init(filenameExtension: "ae")!]; panel.nameFieldStringValue = "\(design.name).ae"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try AeryFile.encode(design).write(to: url, atomically: true, encoding: .utf8); status = "Glider Saved" } catch { status = "Could not save design: \(error.localizedDescription)" }
    }
}

private struct AeryBar: View {
    let label: String; @Binding var value: Double; let range: ClosedRange<Double>; let help: String; @Binding var status: String
    var body: some View {
        HStack(spacing: 7) {
            Slider(value: $value, in: range).tint(.gray).onHover { if $0 { status = help } }
                .frame(width: 210).background(Color.black.opacity(0.72)).clipShape(Rectangle())
            TextField("", value: $value, format: .number.precision(.fractionLength(2))).frame(width: 58).textFieldStyle(.roundedBorder)
            Text(label).font(.system(size: 12, weight: .semibold)).frame(width: 105, alignment: .leading)
        }
    }
}

private struct PlanView: View {
    let design: GliderDesign; let tab: AeryTab
    var body: some View { Canvas { context, size in
        let scale = min((size.width - 50) / max(design.fuselageLength, 1), (size.height - 35) / max(design.wing.span, 1))
        let y = size.height * 0.55; let x = 25.0
        func line(_ a: CGPoint, _ b: CGPoint, _ width: CGFloat = 2) { var p = Path(); p.move(to: a); p.addLine(to: b); context.stroke(p, with: .color(.black), lineWidth: width) }
        if tab == .verticalTail { surface(context: context, origin: CGPoint(x: x + 50, y: y + 50), surface: design.verticalTail, vertical: true, scale: scale) }
        else if tab == .wing { surface(context: context, origin: CGPoint(x: size.width / 2, y: y), surface: design.wing, vertical: false, scale: scale) }
        else if tab == .stabilizer { surface(context: context, origin: CGPoint(x: size.width / 2, y: y), surface: design.stabilizer, vertical: false, scale: scale) }
        else { line(CGPoint(x: x, y: y), CGPoint(x: x + design.fuselageLength * scale, y: y), 3); surface(context: context, origin: CGPoint(x: x + design.wingLocation * scale, y: y), surface: design.wing, vertical: false, scale: scale); surface(context: context, origin: CGPoint(x: x + design.stabilizerLocation * scale, y: y), surface: design.stabilizer, vertical: false, scale: scale); surface(context: context, origin: CGPoint(x: x + design.verticalTailLocation * scale, y: y), surface: design.verticalTail, vertical: true, scale: scale) }
    }.background(.white).overlay(alignment: .topLeading) { Text(tab == .verticalTail ? "Vertical Tail" : "Front").padding(8).fontWeight(.semibold) } }
    private func surface(context: GraphicsContext, origin: CGPoint, surface: Surface, vertical: Bool, scale: CGFloat) {
        let span = surface.span * scale * (vertical ? 1 : 0.5); let root = surface.rootChord * scale; let tip = surface.tipChord * scale; let sweep = surface.tipSweep * scale
        var p = Path()
        if vertical { p.move(to: origin); p.addLine(to: CGPoint(x: origin.x + root, y: origin.y)); p.addLine(to: CGPoint(x: origin.x + sweep + tip, y: origin.y - span)); p.addLine(to: CGPoint(x: origin.x + sweep, y: origin.y - span)); p.closeSubpath() }
        else { p.move(to: origin); p.addLine(to: CGPoint(x: origin.x + root, y: origin.y)); p.addLine(to: CGPoint(x: origin.x + sweep + tip, y: origin.y - span)); p.addLine(to: CGPoint(x: origin.x + sweep, y: origin.y - span)); p.closeSubpath(); p.move(to: origin); p.addLine(to: CGPoint(x: origin.x + root, y: origin.y)); p.addLine(to: CGPoint(x: origin.x + sweep + tip, y: origin.y + span)); p.addLine(to: CGPoint(x: origin.x + sweep, y: origin.y + span)); p.closeSubpath() }
        context.stroke(p, with: .color(.black), lineWidth: 2)
    }
}

private struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss; @Binding var configuration: WoodConfiguration
    var body: some View { VStack(alignment: .leading) { Text("Edit Configuration").font(.title2); TextField("Configuration Name", text: $configuration.name); HStack { number("Max Wing Span (cm)", $configuration.maximumWingSpan); number("Max Wing Width (cm)", $configuration.maximumWingWidth) }; HStack { number("Wing Thickness (cm)", $configuration.wingThickness); number("Wing Density (kg/m³)", $configuration.wingDensity) }; HStack { number("Max Fuselage Length (cm)", $configuration.maximumFuselageLength); number("Max Nose Mass (g)", $configuration.maximumNoseMass) }; HStack { number("Air Density (kg/m³)", $configuration.airDensity); number("Airfoil CL,alpha", $configuration.airfoilLiftSlope) }; HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.defaultAction) } }.padding().frame(width: 540) }
    private func number(_ label: String, _ value: Binding<Double>) -> some View { TextField(label, value: value, format: .number).textFieldStyle(.roundedBorder) }
}
