import SwiftUI

/// Ideas for a date, a gift or something to do with one person, written by Apple Intelligence on
/// the device. Each idea links to matching places nearby on an Apple Maps map.
struct IdeasView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PeopleViewModel.self) private var people
    @Environment(IdeaServices.self) private var services
    @State private var viewModel: IdeasViewModel
    @FocusState private var isNoteFocused: Bool

    init(viewModel: IdeasViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var model = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if services.availability == .available {
                        section("Wofür?") {
                            IdeaCategoryPicker(selection: $model.category, relationship: viewModel.person.relationship)
                        }
                        section("Budget") {
                            Picker("Budget", selection: $model.budget) {
                                ForEach(IdeaBudget.allCases) { budget in
                                    Text(budget.title).tag(budget)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        section("Was mag \(viewModel.name)?") {
                            noteField
                        }
                        generateButton
                        results
                    } else {
                        unavailableCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .animation(.smooth, value: viewModel.phase)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.closerBackground.ignoresSafeArea())
            .navigationTitle("Ideen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .navigationDestination(for: Idea.self) { idea in
                IdeaPlacesView(
                    idea: idea,
                    viewModel: IdeaPlacesViewModel(query: idea.placeSearch, placeSearch: services.placeSearch)
                )
            }
        }
        .tint(.closerAccent)
        // Keeps checking while the model downloads, so the screen switches to the ideas by itself.
        .task { await services.waitWhileModelLoads() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "sparkles")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.closerOnAvatar)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.closerHeroAccent))
                .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isLoading)

            VStack(alignment: .leading, spacing: 6) {
                Text("Ideen für \(viewModel.name)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.closerOnHero)
                Text("Apple Intelligence denkt direkt auf deinem iPhone mit. Was du eingibst, verlässt dein Gerät nicht.")
                    .font(.subheadline)
                    .foregroundStyle(.closerOnHero.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closerHero)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Inputs

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private var noteField: some View {
        @Bindable var model = viewModel
        return TextField(
            "Was mag \(viewModel.name)?",
            text: $model.note,
            prompt: Text("z. B. Sushi, Wandern, Krimis (optional)"),
            axis: .vertical
        )
        .lineLimit(1...3)
        .focused($isNoteFocused)
        .submitLabel(.done)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.closerSurface))
        .onChange(of: viewModel.note) { _, note in
            // Vertical text fields insert a newline on return; treat it as "done".
            if note.contains("\n") {
                viewModel.note = note.replacingOccurrences(of: "\n", with: "")
                isNoteFocused = false
            }
        }
    }

    private var generateButton: some View {
        Button {
            isNoteFocused = false
            Task { await viewModel.generate() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.closerOnAccent)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isLoading ? "Ideen werden erdacht …" : "Ideen finden")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Color.closerOnAccent)
            .background(Capsule().fill(Color.closerAccent))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
        .accessibilityIdentifier("findIdeasButton")
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()
        case .loading:
            if viewModel.ideas.isEmpty {
                IdeaLoadingView()
                    .transition(.opacity)
            } else {
                ideaList
            }
        case .loaded:
            ideaList
        case .failed(let error):
            failureCard(error)
        }
    }

    private var ideaList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(viewModel.ideas) { idea in
                IdeaCardView(idea: idea, isSaved: viewModel.isSaved(idea)) {
                    withAnimation(.snappy) {
                        people.save(idea.makeReminder(), for: viewModel.person.id)
                        viewModel.markSaved(idea)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .opacity(viewModel.isLoading ? 0.5 : 1)

            Button {
                Task { await viewModel.generate(more: true) }
            } label: {
                Label("Neue Ideen", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().strokeBorder(Color.closerAccent, lineWidth: 1.5))
                    .foregroundStyle(.closerAccent)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .padding(.top, 4)

            Text("Vorschläge von Apple Intelligence können ungenau sein. „Erinnern“ legt bei \(viewModel.name) eine Erinnerung in einer Woche an.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func failureCard(_ error: IdeaGenerationError) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Keine Ideen", systemImage: "exclamationmark.bubble")
                .font(.headline)
                .foregroundStyle(.closerAccent)
            Text(error.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Erneut versuchen") {
                Task { await viewModel.generate() }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closerSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Unavailable

    private var unavailableCard: some View {
        let availability = services.availability
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "apple.intelligence")
                Text("Apple Intelligence: \(availability.statusTitle)")
            }
            .font(.headline)
            AppleIntelligenceChecklist(availability: availability)
            Text(availability == .notReady
                 ? availability.statusMessage + " Sobald es fertig ist, erscheinen hier die Ideen von selbst."
                 : availability.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if availability.offersSettings {
                AppleIntelligenceSettingsButton()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closerSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
