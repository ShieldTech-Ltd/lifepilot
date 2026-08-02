import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Animated launch moment that introduces the live orchestration model.
public struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasEntered = false
    private let session: DemoSessionStore

    public init(session: DemoSessionStore) {
        self.session = session
    }

    @MainActor
    public init() {
        self.init(session: DemoSessionStore())
    }

    public var body: some View {
        ZStack {
            AmbientBackground(energy: .prominent)

            Color.LifePilot.backgroundPrimary
                .opacity(colorScheme == .dark ? 0.20 : 0.32)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: Spacing.lg) {
                Spacer(minLength: Spacing.xl)

                VStack(spacing: Spacing.sm) {
                    Image("LifePilotLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(.white.opacity(0.24), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.22), radius: 24, y: 14)

                    Text("LifePilot")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.LifePilot.textPrimary)

                    Label("Private on device", systemImage: "lock.fill")
                        .font(.LifePilot.utility)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                .frame(maxWidth: .infinity)

                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Know what's next")
                                .font(.LifePilot.titleLarge)
                                .foregroundStyle(Color.LifePilot.textPrimary)

                            Text("Event, location and preparation at a glance.")
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }

                        Divider()

                        nextEventPreview
                    }
                }

                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(Color.LifePilot.accentStart)

                    Text("Preparing your briefing")
                        .font(.LifePilot.body.weight(.semibold))
                        .foregroundStyle(Color.LifePilot.textPrimary)
                }
                .padding(.horizontal, Spacing.md)

                Spacer(minLength: Spacing.lg)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 520)
            .scaleEffect(hasEntered ? 1 : 0.97)
            .offset(y: hasEntered ? 0 : 14)
            .opacity(hasEntered ? 1 : 0)
        }
        .task { await session.prepare() }
        .onAppear {
            if reduceMotion {
                hasEntered = true
                return
            }
            withAnimation(.spring(response: 0.75, dampingFraction: 0.78)) {
                hasEntered = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LifePilot is preparing your briefing")
    }

    @ViewBuilder
    private var nextEventPreview: some View {
        if let event = nextEvent {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("UP NEXT", systemImage: "calendar.badge.clock")
                    .font(.LifePilot.utility)
                    .foregroundStyle(Color.LifePilot.accentStart)

                Text(event.title)
                    .font(.LifePilot.titleMedium)
                    .foregroundStyle(Color.LifePilot.textPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(eventTime(event), systemImage: "clock.fill")
                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location.fill")
                            .lineLimit(2)
                    }
                }
                .font(.LifePilot.caption)
                .foregroundStyle(Color.LifePilot.textSecondary)
            }
        } else {
            HStack(spacing: Spacing.md) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.LifePilot.accentStart)
                Text("Finding your next event")
                    .font(.LifePilot.body.weight(.semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)
            }
            .frame(minHeight: 56)
        }
    }

    private var nextEvent: CalendarEvent? {
        let now = session.model?.generatedAt ?? Date()
        return session.visibleEvents.first { $0.endDate > now }
    }

    private func eventTime(_ event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let day = if calendar.isDateInToday(event.startDate) {
            "Today"
        } else if calendar.isDateInTomorrow(event.startDate) {
            "Tomorrow"
        } else {
            event.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
        return "\(day), \(event.startDate.formatted(date: .omitted, time: .shortened))"
    }
}

#Preview { SplashView() }
