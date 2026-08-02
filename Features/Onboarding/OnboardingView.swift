import LifePilotDesignSystem
import SwiftUI

public struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = OnboardingViewModel()
    private let session: DemoSessionStore
    private let onFinish: () -> Void

    public init(session: DemoSessionStore, onFinish: @escaping () -> Void) {
        self.session = session
        self.onFinish = onFinish
    }

    public init(onFinish: @escaping () -> Void) {
        self.init(session: DemoSessionStore(), onFinish: onFinish)
    }

    public var body: some View {
        ZStack {
            AmbientBackground(energy: .subtle)

            VStack(spacing: Spacing.lg) {
                topBar

                Spacer(minLength: Spacing.sm)

                CardContainer {
                    VStack(spacing: Spacing.lg) {
                        stepGraphic

                        VStack(spacing: Spacing.sm) {
                            Text(viewModel.currentStep.title)
                                .font(.LifePilot.titleLarge)
                                .foregroundStyle(Color.LifePilot.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(viewModel.currentStep.message)
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, Spacing.sm)
                        }

                        contextPill
                    }
                    .frame(maxWidth: .infinity, minHeight: 390)
                }
                .id(viewModel.currentStep.id)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

                Spacer(minLength: Spacing.sm)

                Button(buttonTitle) {
                    if viewModel.isLastStep {
                        onFinish()
                    } else {
                        withAnimation(Motion.deliberate) { viewModel.advance() }
                    }
                }
                .buttonStyle(.lifePilotPrimary)
                .accessibilityIdentifier("onboarding.continue")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .lifePilotAnimation(Motion.deliberate, reduceMotion: reduceMotion, value: viewModel.currentStepIndex)
    }

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(Motion.standard) { viewModel.goBack() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.LifePilot.textPrimary)
                    .frame(width: 44, height: 44)
                    .lifePilotGlass(cornerRadius: CornerRadius.full)
            }
            .buttonStyle(.lifePilotPressable)
            .opacity(viewModel.currentStepIndex == 0 ? 0 : 1)
            .disabled(viewModel.currentStepIndex == 0)
            .accessibilityIdentifier("onboarding.back")

            Spacer()

            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.currentStepIndex
                            ? Color.LifePilot.accentStart
                            : Color.LifePilot.textSecondary.opacity(0.18))
                        .frame(width: index == viewModel.currentStepIndex ? 28 : 8, height: 8)
                }
            }

            Spacer()

            Text("\(viewModel.currentStepIndex + 1)/\(viewModel.steps.count)")
                .font(.LifePilot.utility)
                .foregroundStyle(Color.LifePilot.textSecondary)
                .frame(width: 44, height: 44)
        }
    }

    private var buttonTitle: String {
        if viewModel.isLastStep { return "Open my briefing" }
        if viewModel.currentStep.id == "calendar" { return "Continue with demo data" }
        return "Continue"
    }

    @ViewBuilder
    private var contextPill: some View {
        Group {
            switch viewModel.currentStep.id {
            case "calendar":
                Label("\(session.connectedSourceCount) UK demo sources ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.LifePilot.signalSuccess)
            case "approvals":
                Label("Approval is always required", systemImage: "lock.shield.fill")
                    .foregroundStyle(Color.LifePilot.signalSuccess)
            case "ready":
                Label("Built around your BSc Computing day", systemImage: "graduationcap.fill")
                    .foregroundStyle(Color.LifePilot.accentStart)
            default:
                Label("Student-first, designed for everyone", systemImage: "person.3.fill")
                    .foregroundStyle(Color.LifePilot.accentEnd)
            }
        }
        .font(.LifePilot.utility)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .lifePilotGlass(cornerRadius: CornerRadius.full)
    }

    @ViewBuilder
    private var stepGraphic: some View {
        if viewModel.currentStep.id == "welcome" {
            Image("LifePilotLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 18, y: 9)
                .accessibilityLabel("LifePilot logo")
        } else {
            Image(systemName: viewModel.currentStep.symbolName)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 112, height: 112)
                .background(iconColor.opacity(0.12), in: Circle())
                .overlay { Circle().stroke(Color.LifePilot.glassBorder, lineWidth: 1) }
        }
    }

    private var iconColor: Color {
        switch viewModel.currentStep.id {
        case "calendar": Color.LifePilot.accentEnd
        case "approvals": Color.LifePilot.signalSuccess
        default: Color.LifePilot.accentStart
        }
    }
}

#Preview { OnboardingView(onFinish: {}) }
