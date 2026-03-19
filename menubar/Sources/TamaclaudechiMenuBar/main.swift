import SwiftUI
import Combine
import Foundation
import Darwin

// MARK: - Mood Animation Types

enum ParticleDirection {
    case up, down, float, drift, spiral
}

struct MoodAnimationConfig {
    let bounceAmplitude: CGFloat
    let bounceFrequency: Double
    let rotationAmplitude: CGFloat
    let rotationFrequency: Double
    let scaleAmplitude: CGFloat
    let scaleFrequency: Double
    let particles: [(symbol: String, count: Int, direction: ParticleDirection, speed: Double, lifetime: Double, spawnY: CGFloat, fontSize: CGFloat, color: Color?)]

    static func config(for mood: String) -> MoodAnimationConfig {
        switch mood.uppercased() {
        case "ECSTATIC":
            return .init(bounceAmplitude: 4.0, bounceFrequency: 3.5, rotationAmplitude: 0.1, rotationFrequency: 4.0,
                         scaleAmplitude: 0.05, scaleFrequency: 6.0,
                         particles: [
                            ("\u{2728}", 4, .up, 20, 1.0, -0.5, 14, nil),
                            ("\u{2B50}", 3, .spiral, 14, 1.5, -0.4, 12, nil),
                            ("\u{1F389}", 2, .up, 16, 1.2, -0.5, 14, nil),
                         ])
        case "EXCITED":
            return .init(bounceAmplitude: 3.0, bounceFrequency: 2.8, rotationAmplitude: 0.06, rotationFrequency: 3.0,
                         scaleAmplitude: 0.03, scaleFrequency: 4.0,
                         particles: [
                            ("\u{26A1}", 3, .up, 16, 1.3, -0.5, 14, nil),
                            ("\u{2728}", 2, .spiral, 12, 1.6, -0.4, 12, nil),
                         ])
        case "HAPPY":
            return .init(bounceAmplitude: 2.0, bounceFrequency: 1.8, rotationAmplitude: 0.02, rotationFrequency: 1.0,
                         scaleAmplitude: 0.02, scaleFrequency: 2.0,
                         particles: [
                            ("\u{2764}\u{FE0F}", 3, .up, 8, 2.5, -0.55, 18, .red),
                            ("\u{2728}", 2, .float, 6, 2.5, -0.4, 10, nil),
                         ])
        case "NEUTRAL":
            return .init(bounceAmplitude: 0.8, bounceFrequency: 0.6, rotationAmplitude: 0, rotationFrequency: 0,
                         scaleAmplitude: 0.01, scaleFrequency: 0.5,
                         particles: [
                            ("\u{00B7}", 2, .float, 3, 3.0, -0.3, 8, nil),
                         ])
        case "TIRED":
            return .init(bounceAmplitude: 1.0, bounceFrequency: 0.4, rotationAmplitude: 0.03, rotationFrequency: 0.3,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("\u{1F4A4}", 2, .drift, 6, 2.5, -0.5, 12, nil),
                            ("z", 2, .drift, 5, 3.0, -0.5, 10, nil),
                         ])
        case "SLEEPY":
            return .init(bounceAmplitude: 0.6, bounceFrequency: 0.3, rotationAmplitude: 0.04, rotationFrequency: 0.2,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("z", 3, .drift, 7, 2.2, -0.5, 12, nil),
                            ("Z", 2, .drift, 5, 2.8, -0.5, 14, nil),
                            ("\u{1F4A4}", 1, .drift, 4, 3.0, -0.5, 12, nil),
                         ])
        case "SLEEPING":
            return .init(bounceAmplitude: 0, bounceFrequency: 0, rotationAmplitude: 0.06, rotationFrequency: 0.15,
                         scaleAmplitude: 0.02, scaleFrequency: 0.3,
                         particles: [
                            ("Z", 3, .drift, 6, 2.5, -0.5, 14, nil),
                            ("z", 3, .drift, 8, 2.0, -0.5, 12, nil),
                            ("\u{2604}", 1, .float, 2, 4.0, -0.4, 10, nil),
                         ])
        case "HUNGRY":
            return .init(bounceAmplitude: 0.5, bounceFrequency: 1.5, rotationAmplitude: 0.08, rotationFrequency: 3.5,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("\u{1F374}", 2, .float, 5, 2.5, -0.3, 12, nil),
                            ("?", 2, .up, 8, 2.0, -0.5, 12, nil),
                         ])
        case "STARVING":
            return .init(bounceAmplitude: 1.5, bounceFrequency: 5.0, rotationAmplitude: 0.12, rotationFrequency: 6.0,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("!", 3, .down, 16, 1.0, -0.3, 14, .red),
                            ("\u{1F525}", 2, .up, 12, 1.3, -0.5, 14, nil),
                            ("\u{1F4A2}", 2, .spiral, 10, 1.5, -0.3, 12, nil),
                         ])
        case "SAD":
            return .init(bounceAmplitude: -1.5, bounceFrequency: 0.3, rotationAmplitude: 0, rotationFrequency: 0,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("\u{1F4A7}", 3, .down, 14, 1.5, 0.3, 12, nil),
                            ("\u{1F4A7}", 2, .down, 10, 2.0, 0.3, 10, nil),
                         ])
        case "LONELY":
            return .init(bounceAmplitude: 0.5, bounceFrequency: 0.3, rotationAmplitude: 0, rotationFrequency: 0,
                         scaleAmplitude: 0, scaleFrequency: 0,
                         particles: [
                            ("\u{00B7}", 3, .float, 3, 4.0, -0.3, 8, nil),
                            ("...", 1, .drift, 2, 5.0, -0.3, 10, nil),
                         ])
        case "ANXIOUS":
            return .init(bounceAmplitude: 1.2, bounceFrequency: 4.0, rotationAmplitude: 0.08, rotationFrequency: 5.0,
                         scaleAmplitude: 0.02, scaleFrequency: 3.0,
                         particles: [
                            ("!", 2, .up, 10, 1.5, -0.5, 12, .yellow),
                            ("\u{26A0}\u{FE0F}", 2, .float, 6, 2.0, -0.3, 12, nil),
                            ("\u{1F4BE}", 1, .up, 8, 1.8, -0.5, 12, nil),
                         ])
        case "CONCERNED":
            return .init(bounceAmplitude: 0.6, bounceFrequency: 0.5, rotationAmplitude: 0.02, rotationFrequency: 0.4,
                         scaleAmplitude: 0.01, scaleFrequency: 0.8,
                         particles: [
                            ("\u{1F49B}", 2, .float, 4, 3.0, -0.4, 14, nil),
                            ("\u{2615}", 1, .drift, 3, 3.5, -0.3, 12, nil),
                         ])
        default:
            return config(for: "NEUTRAL")
        }
    }
}

struct AnimatedMascotView: View {
    let mood: String
    let mascotImage: NSImage?
    let size: CGFloat

    @State private var tick = Date()
    private let timer = Timer.publish(every: 1.0 / 15, on: .main, in: .common).autoconnect()

    init(mood: String, mascotImage: NSImage? = NSImage(named: "MascotColor"), size: CGFloat = 64) {
        self.mood = mood
        self.mascotImage = mascotImage
        self.size = size
    }

    var body: some View {
        let time = tick.timeIntervalSinceReferenceDate
        let config = MoodAnimationConfig.config(for: mood)
        let scale = size / 64.0
        let bounce = config.bounceAmplitude * scale * sin(time * config.bounceFrequency * .pi * 2)
        let rotation = config.rotationAmplitude * sin(time * config.rotationFrequency * .pi * 2)
        let pulse = 1.0 + config.scaleAmplitude * sin(time * config.scaleFrequency * .pi * 2)

        ZStack {
            if let img = mascotImage {
                Image(nsImage: img)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
                    .scaleEffect(pulse)
                    .offset(y: bounce)
                    .rotationEffect(.radians(rotation))
            } else {
                Image(systemName: "hare")
                    .font(.system(size: size * 0.6))
            }

            ForEach(Array(config.particles.enumerated()), id: \.offset) { groupIdx, group in
                ForEach(0..<group.count, id: \.self) { i in
                    particleView(
                        index: i, groupSeed: Double(groupIdx) * 13.7,
                        symbol: group.symbol, direction: group.direction,
                        speed: group.speed, lifetime: group.lifetime,
                        spawnY: group.spawnY, fontSize: group.fontSize, color: group.color,
                        time: time, scale: scale
                    )
                }
            }
        }
        .frame(width: size * 2.0, height: size * 1.8)
        .onReceive(timer) { tick = $0 }
    }

    private func particleView(index i: Int, groupSeed: Double, symbol: String,
                               direction: ParticleDirection, speed: Double, lifetime: Double,
                               spawnY: CGFloat, fontSize baseFontSize: CGFloat, color: Color?,
                               time: Double, scale: CGFloat) -> some View {
        let seed = Double(i) * 1.7 + groupSeed
        let stagger = Double(i) * (lifetime / max(Double(1), Double(i + 1)))
        let age = (time + stagger).truncatingRemainder(dividingBy: lifetime)
        let progress = age / lifetime

        let fadeIn: Double = progress < 0.1 ? progress / 0.1 : 1.0
        let fadeOut: Double = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0
        let opacity = fadeIn * fadeOut

        let spawnX: CGFloat = CGFloat(sin(seed * 3.14) * 8.0) * scale
        let originY: CGFloat = spawnY * size
        let travel = CGFloat(progress) * CGFloat(speed) * scale
        var px: CGFloat = spawnX
        var py: CGFloat = originY

        switch direction {
        case .up:
            py -= travel
            px += sin(time * 2 + seed) * 3 * scale
        case .down:
            py += travel
            px += sin(time * 2 + seed) * 3 * scale
        case .float:
            py -= travel * 0.4
            px += sin(time * 1.2 + seed) * 5 * scale
        case .drift:
            py -= travel * 0.7
            px += travel * 0.5 + sin(time + seed) * 2 * scale
        case .spiral:
            let radius = travel * 0.4
            px += cos(time * 3 + seed * 2) * radius
            py -= sin(time * 3 + seed * 2) * radius - travel * 0.3
        }

        let particleScale: CGFloat = 0.8 + 0.4 * CGFloat(sin(time * 3 + seed))
        let computedFontSize: CGFloat = baseFontSize * scale * particleScale

        return Text(symbol)
            .font(.system(size: computedFontSize))
            .foregroundColor(color)
            .offset(x: px, y: py)
            .opacity(opacity)
    }
}

@main
struct TamaclaudechiMenuBarApp: App {
    @StateObject private var viewModel = MascotViewModel()
    @StateObject private var configManager = ConfigManager()

    init() {
        // SPM executables don't populate Bundle.main.resourcePath correctly.
        // Resolve from executable → ../Resources/
        if let execURL = Bundle.main.executableURL {
            let resourcesDir = execURL
                .deletingLastPathComponent()       // MacOS/
                .deletingLastPathComponent()       // Contents/
                .appendingPathComponent("Resources")

            // Template icon for the menu bar (monochrome)
            let templateURL = resourcesDir.appendingPathComponent("MascotTemplate.png")
            if let image = NSImage(contentsOf: templateURL) {
                image.isTemplate = true
                image.setName("MascotTemplate")
            }

            // Full-color mascot for the popover
            let colorURL = resourcesDir.appendingPathComponent("MascotColor.png")
            if let image = NSImage(contentsOf: colorURL) {
                image.isTemplate = false
                image.setName("MascotColor")
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MascotView(viewModel: viewModel, configManager: configManager)
                .frame(width: 320)
        } label: {
            // Simple single Image — dynamic squish based on fatigue.
            // MenuBarExtra's label is extremely restrictive; complex views cause fallback.
            Image(nsImage: viewModel.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}

final class MascotViewModel: ObservableObject {
    @Published private(set) var snapshot: MascotSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published private(set) var menuBarIcon: NSImage

    private var originalTemplateImage: NSImage?
    private var timer: Timer?
    private let cliPath: String
    private let stateWatchQueue = DispatchQueue(label: "app.claude.mascot.statewatch", qos: .utility)
    private var stateFileSource: DispatchSourceFileSystemObject?
    private var stateDirSource: DispatchSourceFileSystemObject?
    private var stateFileDescriptor: CInt = -1
    private var stateDirDescriptor: CInt = -1

    init(cliPath: String = MascotPaths.cliExecutable()) {
        self.cliPath = cliPath

        let template = NSImage(named: "MascotTemplate")
        self.originalTemplateImage = template
        self.menuBarIcon = template ?? NSImage(systemSymbolName: "hare", accessibilityDescription: nil)!

        Task { await refresh() }

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { await self?.refresh(background: true) }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        configureStateWatchers()
    }

    deinit {
        timer?.invalidate()
        cancelStateFileWatcher()
        cancelStateDirectoryWatcher()
    }

    var menuTitle: String {
        snapshot?.displayName ?? "Claude"
    }

    var menuIconName: String {
        snapshot?.palette.icon ?? "face.smiling"
    }

    @MainActor
    func refresh(background: Bool = false) async {
        if !background {
            isLoading = true
            errorMessage = nil
        }

        do {
            let newSnapshot = try await fetchSnapshot()
            snapshot = newSnapshot
            lastUpdated = Date()
            updateMenuBarIcon()
            isLoading = false
        } catch {
            errorMessage = error.readableDescription
            isLoading = false
        }
    }

    private func updateMenuBarIcon() {
        guard let original = originalTemplateImage, let snapshot = snapshot else { return }

        let rest = Double(snapshot.stats.rest)
        let energy = Double(snapshot.stats.energy)
        let fatigue = min(rest, energy) / 100.0  // 0.0=exhausted, 1.0=full
        let squish = (1.0 - fatigue) * 0.5       // 0.0=no squish, 0.5=max squish

        if squish < 0.01 {
            // No visible squish — use original
            menuBarIcon = original
            return
        }

        let size = original.size
        let scaleY = 1.0 - squish
        let newImage = NSImage(size: size, flipped: false) { rect in
            let drawHeight = size.height * scaleY
            let drawRect = NSRect(x: 0, y: 0, width: size.width, height: drawHeight)
            original.draw(in: drawRect, from: NSRect(origin: .zero, size: size),
                          operation: .sourceOver, fraction: 1.0)
            return true
        }
        newImage.isTemplate = true
        menuBarIcon = newImage
    }

    private func fetchSnapshot() async throws -> MascotSnapshot {
        let data = try await runCommand(arguments: ["status", "--json"])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(MascotSnapshot.self, from: data)
    }

    private func runCommand(arguments: [String]) async throws -> Data {
        return try await Task.detached(priority: .background) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.cliPath)
            process.arguments = arguments

            let output = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = output
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw MascotError.commandFailed(message ?? "Command failed with code \(process.terminationStatus)")
            }

            return output.fileHandleForReading.readDataToEndOfFile()
        }.value
    }

    private func configureStateWatchers() {
        startStateDirectoryWatcher()
        startStateFileWatcher()
    }

    private func startStateFileWatcher() {
        cancelStateFileWatcher()
        let path = MascotPaths.stateFile.path
        guard FileManager.default.fileExists(atPath: path) else { return }

        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        stateFileDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename], queue: stateWatchQueue)
        source.setEventHandler { [weak self, weak source] in
            guard let self else { return }
            if let events = source?.data, (events.contains(.delete) || events.contains(.rename)) {
                self.cancelStateFileWatcher()
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                    self.startStateFileWatcher()
                }
            }
            Task { await self.refresh(background: true) }
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.stateFileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.stateFileDescriptor = -1
        }
        stateFileSource = source
        source.resume()
    }

    private func startStateDirectoryWatcher() {
        cancelStateDirectoryWatcher()
        let directory = MascotPaths.stateDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        stateDirDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename], queue: stateWatchQueue)
        source.setEventHandler { [weak self] in
            self?.startStateFileWatcher()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.stateDirDescriptor, fd >= 0 {
                close(fd)
            }
            self?.stateDirDescriptor = -1
        }
        stateDirSource = source
        source.resume()
    }

    private func cancelStateFileWatcher() {
        stateFileSource?.cancel()
        stateFileSource = nil
        if stateFileDescriptor >= 0 {
            close(stateFileDescriptor)
            stateFileDescriptor = -1
        }
    }

    private func cancelStateDirectoryWatcher() {
        stateDirSource?.cancel()
        stateDirSource = nil
        if stateDirDescriptor >= 0 {
            close(stateDirDescriptor)
            stateDirDescriptor = -1
        }
    }
}

private enum MascotError: Error {
    case commandFailed(String)
}

private extension Error {
    var readableDescription: String {
        if let mascotError = self as? MascotError, case let .commandFailed(message) = mascotError {
            return message
        }
        return localizedDescription
    }
}

struct MascotSnapshot: Decodable {
    struct Stats: Decodable {
        let energy: Int
        let serenity: Int
        let rest: Int
        let appetite: Int
        let bond: Int
    }

    struct Details: Decodable {
        let serenity: SerenityDetails?
        let rest: RestDetails?
        let appetite: AppetiteDetails?
        let bond: BondDetails?
        let energy: EnergyDetails?
    }

    struct SerenityDetails: Decodable {
        let inGitRepo: Bool
        let dirtyCount: Int
        let branchCount: Int
        let mergedStaleCount: Int
        let diffInsertions: Int
        let diffDeletions: Int
        let lastCommitAgoSecs: Int
    }

    struct RestDetails: Decodable {
        let sessionMinutes: Int
        let workStartIso: String?
        let currentHour: Int
        let lateNightPenalty: Int
        let isMarathon: Bool
        let interactionDensity: Int?
    }

    struct AppetiteDetails: Decodable {
        let lastFoodGroup: String?
        let foodGroupStreak: Int
        let groupsToday: [String]
    }

    struct BondDetails: Decodable {
        let streakDays: Int
        let todayInteractions: Int
        let sessionMinutes: Int
        let lifetimeInteractions: Int
        let daysSinceFirstMet: Int
    }

    struct EnergyDetails: Decodable {
        let circadianTarget: Int
        let circadianPhase: String
    }

    struct DayActivity: Decodable {
        let date: String
        let interactions: Int
    }

    let mood: String
    let personality: String
    let stats: Stats
    let wellbeing: Int
    let name: String?
    let streak: Int
    let lifetime: Int
    let achievementUnlocked: String?
    let details: Details?
    let history: [DayActivity]?

    var displayName: String {
        name ?? "Claude Mascot"
    }

    var palette: MoodPalette {
        MoodPalette.mood(for: mood)
    }
}

struct MascotView: View {
    @ObservedObject var viewModel: MascotViewModel
    @ObservedObject var configManager: ConfigManager
    @State private var showSettings = false

    var body: some View {
        if showSettings {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: { showSettings = false }) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    Text("Settings")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 12)

                SettingsView(configManager: configManager)
            }
            .padding(16)
            .frame(width: 320)
        } else {
            mascotContent
        }
    }

    private var mascotContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let snapshot = viewModel.snapshot {
                HeaderSection(snapshot: snapshot)
                StatsSection(snapshot: snapshot)
                ActivityStrip(history: snapshot.history ?? [], todayInteractions: snapshot.details?.bond?.todayInteractions ?? 0)
                QuickInfoSection(snapshot: snapshot)
                if let updated = viewModel.lastUpdated {
                    HStack {
                        Text("Updated \(updated, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                emptyView
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var loadingView: some View {
        VStack(alignment: .center) {
            ProgressView()
            Text("Summoning mascot...")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Couldn't load mascot", systemImage: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text(message)
                .font(.footnote)
            Button("Retry") {
                Task { await viewModel.refresh() }
            }
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No stats yet")
                .font(.headline)
            Button("Refresh") {
                Task { await viewModel.refresh() }
            }
        }
    }
}

private struct HeaderSection: View {
    let snapshot: MascotSnapshot

    var body: some View {
        VStack(spacing: 4) {
            AnimatedMascotView(mood: snapshot.mood)
            Text(snapshot.mood.capitalized)
                .font(.caption2)
                .foregroundColor(snapshot.palette.accent)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatsSection: View {
    let snapshot: MascotSnapshot
    @State var expandedStat: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StatRow(label: "Energy", value: snapshot.stats.energy, color: .yellow,
                    info: "Follows a circadian rhythm \u{2014} peaks during the day, drops at night.",
                    isExpanded: expandedStat == "Energy",
                    onTap: { toggleStat("Energy") }) {
                if let d = snapshot.details?.energy {
                    EnergyDetail(details: d)
                }
            }
            StatRow(label: "Serenity", value: snapshot.stats.serenity, color: .teal,
                    info: "Reflects how tidy the repo is.",
                    disabled: snapshot.details?.serenity?.inGitRepo == false,
                    isExpanded: expandedStat == "Serenity",
                    onTap: { toggleStat("Serenity") }) {
                if let d = snapshot.details?.serenity {
                    SerenityDetail(details: d)
                }
            }
            StatRow(label: "Rest", value: snapshot.stats.rest, color: .mint,
                    info: "Recovers during breaks. Penalized by late-night work.",
                    isExpanded: expandedStat == "Rest",
                    onTap: { toggleStat("Rest") }) {
                if let d = snapshot.details?.rest {
                    RestDetail(details: d)
                }
            }
            StatRow(label: "Appetite", value: snapshot.stats.appetite, color: .orange,
                    info: "Fed by variety! Different work types are different food groups.",
                    isExpanded: expandedStat == "Appetite",
                    onTap: { toggleStat("Appetite") }) {
                if let d = snapshot.details?.appetite {
                    AppetiteDetail(details: d)
                }
            }
            StatRow(label: "Bond", value: snapshot.stats.bond, color: .purple,
                    info: "Grows through consistency \u{2014} daily streaks and long sessions.",
                    isExpanded: expandedStat == "Bond",
                    onTap: { toggleStat("Bond") }) {
                if let d = snapshot.details?.bond {
                    BondDetail(details: d)
                }
            }
        }
    }

    private func toggleStat(_ stat: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedStat = expandedStat == stat ? nil : stat
        }
    }
}

private struct QuickInfoSection: View {
    let snapshot: MascotSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                InfoTile(title: "Wellbeing", value: "\(snapshot.wellbeing)/100")
                InfoTile(title: "Streak", value: "\(snapshot.streak)d")
                InfoTile(title: "Lifetime", value: "\(snapshot.lifetime)")
            }
            if let achievement = snapshot.achievementUnlocked {
                Label("Unlocked: \(achievement)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
    }
}

private struct StatRow<DetailContent: View>: View {
    let label: String
    let value: Int
    let color: Color
    let info: String
    var disabled: Bool = false
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let detailContent: () -> DetailContent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(disabled ? .secondary : nil)
                    .help(info)
                Spacer()
                Text(disabled ? "—" : "\(value)/100")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    if !disabled {
                        Capsule()
                            .fill(color)
                            .frame(width: proxy.size.width * CGFloat(value) / 100)
                    }
                }
            }
            .frame(height: 6)

            if isExpanded {
                detailContent()
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Stat Detail Views

private struct DetailRow: View {
    let icon: String
    let text: String
    var color: Color = .secondary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 14)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct SerenityDetail: View {
    let details: MascotSnapshot.SerenityDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if !details.inGitRepo {
                DetailRow(icon: "xmark.circle", text: "Not in a git repo", color: .secondary)
            } else {
                if details.dirtyCount == 0 {
                    DetailRow(icon: "checkmark.circle", text: "Clean working tree", color: .green)
                } else {
                    DetailRow(icon: "doc.badge.ellipsis", text: "\(details.dirtyCount) dirty files",
                              color: details.dirtyCount > 20 ? .red : .orange)
                }

                let branchLabel = details.branchCount > 3
                    ? "\(details.branchCount) branches (\(details.branchCount - 3) over limit)"
                    : "\(details.branchCount) branches"
                DetailRow(icon: "arrow.triangle.branch", text: branchLabel,
                          color: details.branchCount > 3 ? .orange : .green)

                if details.mergedStaleCount > 0 {
                    DetailRow(icon: "arrow.triangle.merge", text: "\(details.mergedStaleCount) stale merged branches", color: .orange)
                }

                if details.diffInsertions > 0 || details.diffDeletions > 0 {
                    DetailRow(icon: "plus.forwardslash.minus", text: "+\(details.diffInsertions) \u{2212}\(details.diffDeletions) uncommitted",
                              color: (details.diffInsertions + details.diffDeletions) > 500 ? .red : .orange)
                }

                let commitAgoMin = details.lastCommitAgoSecs / 60
                let commitText: String = {
                    if commitAgoMin < 1 { return "Last commit: just now" }
                    if commitAgoMin < 60 { return "Last commit: \(commitAgoMin)m ago" }
                    let hours = commitAgoMin / 60
                    if hours < 24 { return "Last commit: \(hours)h ago" }
                    return "Last commit: \(hours / 24)d ago"
                }()
                DetailRow(icon: "clock", text: commitText,
                          color: commitAgoMin < 60 ? .green : .secondary)
            }
        }
    }
}

private struct RestDetail: View {
    let details: MascotSnapshot.RestDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            let hours = details.sessionMinutes / 60
            let mins = details.sessionMinutes % 60
            let sessionText = hours > 0 ? "Session: \(hours)h \(mins)m" : "Session: \(mins)m"
            DetailRow(icon: "timer", text: sessionText)

            if let ws = details.workStartIso {
                let startTime = formatTime(ws)
                DetailRow(icon: "sunrise", text: "Started at \(startTime)")
            }

            if details.lateNightPenalty > 0 {
                DetailRow(icon: "moon.stars", text: "Late-night penalty: \u{2212}\(details.lateNightPenalty)", color: .orange)
            }

            if details.isMarathon {
                DetailRow(icon: "exclamationmark.triangle", text: "Marathon session!", color: .red)
            }

            if let density = details.interactionDensity, density > 0 {
                DetailRow(
                    icon: "bolt.heart",
                    text: densityLabel(density),
                    color: densityColor(density)
                )
            }
        }
    }

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) ?? fallback.date(from: iso) else { return iso }
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func densityLabel(_ density: Int) -> String {
        if density > 20 { return "Very intense (\(density)/hr)" }
        if density >= 15 { return "Intense (\(density)/hr)" }
        if density >= 5 { return "Moderate (\(density)/hr)" }
        return "Light (\(density)/hr)"
    }

    private func densityColor(_ density: Int) -> Color {
        if density > 20 { return .red }
        if density >= 15 { return .orange }
        if density >= 5 { return .green }
        return .blue
    }
}

private struct AppetiteDetail: View {
    let details: MascotSnapshot.AppetiteDetails

    private struct FoodGroupPill: View {
        let name: String
        let icon: String
        let color: Color
        let active: Bool

        var body: some View {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                Text(name)
                    .font(.system(size: 9))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(active ? color.opacity(0.3) : Color.gray.opacity(0.1)))
            .foregroundColor(active ? color : .secondary.opacity(0.5))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                FoodGroupPill(name: "Protein", icon: "hammer.fill", color: .red,
                              active: details.groupsToday.contains("protein"))
                FoodGroupPill(name: "Veg", icon: "leaf.fill", color: .green,
                              active: details.groupsToday.contains("vegetables"))
                FoodGroupPill(name: "Carbs", icon: "bubble.left.fill", color: .yellow,
                              active: details.groupsToday.contains("carbs"))
                FoodGroupPill(name: "Fiber", icon: "doc.text.fill", color: .brown,
                              active: details.groupsToday.contains("fiber"))
            }
            if let lastGroup = details.lastFoodGroup, details.foodGroupStreak > 1 {
                Text("Last: \(lastGroup.capitalized) \u{00D7}\(details.foodGroupStreak) (diminishing)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct BondDetail: View {
    let details: MascotSnapshot.BondDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            DetailRow(icon: "flame", text: "\(details.streakDays) day streak",
                      color: details.streakDays >= 7 ? .orange : .secondary)
            DetailRow(icon: "text.bubble", text: "\(details.todayInteractions) interactions today")
            let hours = details.sessionMinutes / 60
            let mins = details.sessionMinutes % 60
            let sessionText = hours > 0 ? "Session: \(hours)h \(mins)m" : "Session: \(mins)m"
            DetailRow(icon: "clock.badge.checkmark", text: sessionText)
            DetailRow(icon: "calendar", text: "\(details.daysSinceFirstMet) days together")
        }
    }
}

private struct EnergyDetail: View {
    let details: MascotSnapshot.EnergyDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            DetailRow(icon: "target", text: "Target: \(details.circadianTarget)")
            let phaseIcon: String = {
                switch details.circadianPhase {
                case "rising": return "sunrise"
                case "plateau": return "sun.max"
                case "winding_down": return "sunset"
                default: return "moon"
                }
            }()
            let phaseLabel: String = {
                switch details.circadianPhase {
                case "rising": return "Rising (6am\u{2013}10am)"
                case "plateau": return "Plateau (10am\u{2013}6pm)"
                case "winding_down": return "Winding down (6pm\u{2013}10pm)"
                case "sleeping": return "Sleep time (10pm\u{2013}6am)"
                default: return details.circadianPhase.capitalized
                }
            }()
            DetailRow(icon: phaseIcon, text: phaseLabel)
        }
    }
}

// MARK: - Activity Strip

private struct ActivityStrip: View {
    let history: [MascotSnapshot.DayActivity]
    let todayInteractions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ACTIVITY")
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<14, id: \.self) { dayOffset in
                    let dayIndex = 13 - dayOffset
                    let isToday = dayIndex == 0
                    let count = interactionCount(daysAgo: dayIndex)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(count: count))
                        .frame(width: 16, height: 16)
                        .overlay(
                            isToday ? RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.5), lineWidth: 1) : nil
                        )
                }
            }

            let best = bestDay()
            Text("Today: \(todayInteractions) | Best: \(best.count)\(best.label.isEmpty ? "" : " (\(best.label))")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func interactionCount(daysAgo: Int) -> Int {
        if daysAgo == 0 { return todayInteractions }
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let target = formatter.string(from: targetDate)
        return history.first(where: { $0.date == target })?.interactions ?? 0
    }

    private func heatColor(count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.15) }
        if count <= 5 { return Color.green.opacity(0.3) }
        if count <= 15 { return Color.green.opacity(0.55) }
        return Color.green.opacity(0.85)
    }

    private func bestDay() -> (count: Int, label: String) {
        var maxCount = todayInteractions
        var maxLabel = "Today"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"

        for entry in history {
            if entry.interactions > maxCount {
                maxCount = entry.interactions
                if let date = formatter.date(from: entry.date) {
                    maxLabel = displayFormatter.string(from: date)
                } else {
                    maxLabel = entry.date
                }
            }
        }
        return (maxCount, maxLabel)
    }
}

private struct InfoTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
    }
}


struct MoodPalette {
    let accent: Color
    let icon: String

    static func mood(for mood: String) -> MoodPalette {
        switch mood.uppercased() {
        case "ECSTATIC":
            return MoodPalette(accent: Color(hex: 0x4ade80), icon: "party.popper")
        case "EXCITED":
            return MoodPalette(accent: Color(hex: 0x22d3ee), icon: "sparkles")
        case "HAPPY":
            return MoodPalette(accent: Color(hex: 0x4ade80), icon: "face.smiling")
        case "NEUTRAL":
            return MoodPalette(accent: Color(hex: 0xe2e8f0), icon: "face.neutral")
        case "TIRED":
            return MoodPalette(accent: Color(hex: 0x94a3b8), icon: "zzz")
        case "SLEEPY":
            return MoodPalette(accent: Color(hex: 0x64748b), icon: "bed.double.fill")
        case "SLEEPING":
            return MoodPalette(accent: Color(hex: 0x475569), icon: "powersleep")
        case "HUNGRY":
            return MoodPalette(accent: Color(hex: 0xfb923c), icon: "fork.knife")
        case "STARVING":
            return MoodPalette(accent: Color(hex: 0xef4444), icon: "flame.fill")
        case "SAD":
            return MoodPalette(accent: Color(hex: 0x818cf8), icon: "cloud.rain")
        case "LONELY":
            return MoodPalette(accent: Color(hex: 0xa78bfa), icon: "person.fill.badge.minus")
        case "ANXIOUS":
            return MoodPalette(accent: Color(hex: 0xfbbf24), icon: "exclamationmark.triangle")
        case "CONCERNED":
            return MoodPalette(accent: Color(hex: 0x38bdf8), icon: "heart.circle")
        default:
            return MoodPalette(accent: Color(hex: 0xffffff), icon: "face.smiling")
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

struct MascotPaths {
    static func cliExecutable() -> String {
        let fm = FileManager.default

        // 1. Env override (always wins)
        if let override = ProcessInfo.processInfo.environment["TAMAGOTCHI_CLI_PATH"],
           fm.isExecutableFile(atPath: override) {
            return override
        }

        // 2. Resolve from running binary location
        //    Binary is at .app/Contents/MacOS/TamagotchiMenuBar
        //    Repo structure: menubar/build/TamagotchiMenuBar.app/Contents/MacOS/
        //    So go up 5 levels to reach repo root, then into scripts/tamagotchi
        if let execURL = Bundle.main.executableURL {
            let repoRoot = execURL
                .deletingLastPathComponent() // MacOS/
                .deletingLastPathComponent() // Contents/
                .deletingLastPathComponent() // TamagotchiMenuBar.app/
                .deletingLastPathComponent() // build/
                .deletingLastPathComponent() // menubar/
            let candidate = repoRoot.appendingPathComponent("scripts/tamagotchi").path
            if fm.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        // 3. Compile-time source path fallback
        //    #filePath is Sources/TamaclaudechiMenuBar/main.swift
        //    Go up 3 levels to reach repo root
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // TamaclaudechiMenuBar/
            .deletingLastPathComponent() // Sources/
            .deletingLastPathComponent() // menubar/
        let cliPath = repoRoot.appendingPathComponent("scripts/tamagotchi").path
        if fm.isExecutableFile(atPath: cliPath) {
            return cliPath
        }

        return cliPath
    }

    static var stateDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("claude-mascot", isDirectory: true)
    }

    static var stateFile: URL {
        stateDirectory.appendingPathComponent("state.json", isDirectory: false)
    }

    static var configFile: URL {
        stateDirectory.appendingPathComponent("config.json", isDirectory: false)
    }
}

// MARK: - Config Manager

struct RepoRootInfo: Identifiable {
    let id: String
    let path: String
    var hasClaudeDir: Bool
    var isGitRepo: Bool

    init(path: String, hasClaudeDir: Bool = false, isGitRepo: Bool = false) {
        self.id = path
        self.path = path
        self.hasClaudeDir = hasClaudeDir
        self.isGitRepo = isGitRepo
    }

    var tildeAbbreviated: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

final class ConfigManager: ObservableObject {
    @Published var repoRoots: [RepoRootInfo] = []

    private let cliPath: String
    private let configWatchQueue = DispatchQueue(label: "app.claude.mascot.configwatch", qos: .utility)
    private var configFileSource: DispatchSourceFileSystemObject?
    private var configDirSource: DispatchSourceFileSystemObject?
    private var configFileDescriptor: CInt = -1
    private var configDirDescriptor: CInt = -1

    init(cliPath: String = MascotPaths.cliExecutable()) {
        self.cliPath = cliPath
        loadConfig()
        configureConfigWatchers()
    }

    deinit {
        cancelConfigFileWatcher()
        cancelConfigDirectoryWatcher()
    }

    func loadConfig() {
        Task {
            do {
                let data = try await runCLI(arguments: ["config", "repo-roots", "--scan"])
                let decoder = JSONDecoder()
                struct ScanResult: Decodable {
                    let path: String
                    let hasClaudeDir: Bool
                    let isGitRepo: Bool
                }
                let results = try decoder.decode([ScanResult].self, from: data)
                let roots = results.map { RepoRootInfo(path: $0.path, hasClaudeDir: $0.hasClaudeDir, isGitRepo: $0.isGitRepo) }
                await MainActor.run { self.repoRoots = roots }
            } catch {
                // Silently fail — config may not exist yet
            }
        }
    }

    func addRepoRoot(path: String) {
        Task {
            do {
                _ = try await runCLI(arguments: ["config", "repo-roots", "--add", path])
                loadConfig()
            } catch {
                // Silently fail
            }
        }
    }

    func removeRepoRoot(path: String) {
        Task {
            do {
                _ = try await runCLI(arguments: ["config", "repo-roots", "--remove", path])
                loadConfig()
            } catch {
                // Silently fail
            }
        }
    }

    private func runCLI(arguments: [String]) async throws -> Data {
        return try await Task.detached(priority: .background) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.cliPath)
            process.arguments = arguments

            let output = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = output
            process.standardError = errorPipe

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw MascotError.commandFailed(message ?? "Command failed with code \(process.terminationStatus)")
            }

            return output.fileHandleForReading.readDataToEndOfFile()
        }.value
    }

    // MARK: Config file watchers

    private func configureConfigWatchers() {
        startConfigDirectoryWatcher()
        startConfigFileWatcher()
    }

    private func startConfigFileWatcher() {
        cancelConfigFileWatcher()
        let path = MascotPaths.configFile.path
        guard FileManager.default.fileExists(atPath: path) else { return }

        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        configFileDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename], queue: configWatchQueue)
        source.setEventHandler { [weak self, weak source] in
            guard let self else { return }
            if let events = source?.data, (events.contains(.delete) || events.contains(.rename)) {
                self.cancelConfigFileWatcher()
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                    self.startConfigFileWatcher()
                }
            }
            self.loadConfig()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.configFileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.configFileDescriptor = -1
        }
        configFileSource = source
        source.resume()
    }

    private func startConfigDirectoryWatcher() {
        cancelConfigDirectoryWatcher()
        let directory = MascotPaths.stateDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        configDirDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .delete, .rename], queue: configWatchQueue)
        source.setEventHandler { [weak self] in
            self?.startConfigFileWatcher()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.configDirDescriptor, fd >= 0 {
                close(fd)
            }
            self?.configDirDescriptor = -1
        }
        configDirSource = source
        source.resume()
    }

    private func cancelConfigFileWatcher() {
        configFileSource?.cancel()
        configFileSource = nil
        if configFileDescriptor >= 0 {
            close(configFileDescriptor)
            configFileDescriptor = -1
        }
    }

    private func cancelConfigDirectoryWatcher() {
        configDirSource?.cancel()
        configDirSource = nil
        if configDirDescriptor >= 0 {
            close(configDirDescriptor)
            configDirDescriptor = -1
        }
    }
}

// MARK: - Settings Window

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GitHub Repo Roots")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if configManager.repoRoots.isEmpty {
                Text("No repo roots configured.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(configManager.repoRoots) { root in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(root.tildeAbbreviated)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    HStack(spacing: 8) {
                                        Label(root.hasClaudeDir ? ".claude" : ".claude", systemImage: root.hasClaudeDir ? "checkmark.circle.fill" : "xmark.circle")
                                            .font(.caption2)
                                            .foregroundColor(root.hasClaudeDir ? .green : .secondary)
                                        Label(root.isGitRepo ? "git" : "git", systemImage: root.isGitRepo ? "checkmark.circle.fill" : "xmark.circle")
                                            .font(.caption2)
                                            .foregroundColor(root.isGitRepo ? .green : .secondary)
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    configManager.removeRepoRoot(path: root.path)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            HStack {
                Button(action: openFolderPicker) {
                    Label("Add Repo Root", systemImage: "plus")
                }
                Spacer()
            }
        }
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select GitHub repo root directories"
        panel.prompt = "Add"

        if panel.runModal() == .OK {
            for url in panel.urls {
                configManager.addRepoRoot(path: url.path)
            }
        }
    }
}
