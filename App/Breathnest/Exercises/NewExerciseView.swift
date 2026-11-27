import BreathnestKit
import SwiftUI

/// Screen 8 of the design: the New exercise sheet. Name, Icon, Description and the Pattern in seconds.
struct NewExerciseView: View {
    @State private var viewModel = NewExerciseViewModel()
    let save: (CustomExerciseRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var nameFocused: Bool

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Button { dismiss() } label: {
                    Text("common.cancel")
                        .designFont(.body, 17, weight: .medium)
                        .foregroundStyle(Color(.ring))
                        .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityIdentifier("newExercise.cancelButton")
                Text("newExercise.title")
                    .designFont(.title, 30, weight: .bold, tracking: -0.02, lineHeight: 1.15)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("newExercise.title")
                VStack(alignment: .leading, spacing: 20) {
                    nameField(scale: scale)
                    iconRow(scale: scale)
                    descriptionField
                    patternGroup(scale: scale)
                }
                addButton(scale: scale)
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color(.fg))
        .background(Color(.bg))
        .presentationDetents([.large])
        .presentationCornerRadius(38)
        .presentationBackground(Color(.bg))
    }

    private func label(_ key: LocalizedStringKey) -> some View {
        Text(key).designFont(.subheadline, 15, weight: .semibold).foregroundStyle(Color(.fg2))
    }

    private func nameField(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label("newExercise.name")
            TextField("", text: $viewModel.name, prompt: Text("newExercise.name.placeholder"))
                .focused($nameFocused)
                .designFont(.body, 17)
                .padding(.horizontal, 16)
                .frame(minHeight: scale(48, 88))
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.surface)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.outline), lineWidth: 1.5))
                .accessibilityLabel(Text("newExercise.name"))
                .accessibilityIdentifier("newExercise.nameField")
        }
    }

    private func iconRow(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label("newExercise.icon")
            WrappingLayout(spacing: 10) {
                ForEach(CustomExerciseIcon.allCases, id: \.self) { icon in
                    let isSelected = icon == viewModel.icon
                    Button { viewModel.icon = icon } label: {
                        Image(systemName: icon.symbolName)
                            .font(.system(size: 26))
                            .foregroundStyle(Color(isSelected ? .ring : .fg2))
                            .frame(width: scale(48, 88), height: scale(48, 88))
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.surface)))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(isSelected ? .ring : .outline), lineWidth: isSelected ? 2.5 : 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon.label)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("newExercise.icon.\(icon.rawValue)")
                }
            }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("newExercise.description")
            TextField(
                "",
                text: $viewModel.details,
                prompt: Text("newExercise.description.placeholder"),
                axis: .vertical
            )
            .lineLimit(2 ... 4)
            .designFont(.body, 17)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 68, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.surface)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.outline), lineWidth: 1.5))
            .accessibilityLabel(Text("newExercise.description"))
            .accessibilityIdentifier("newExercise.descriptionField")
        }
    }

    private func patternGroup(scale: DesignScale) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                label("newExercise.pattern")
                Spacer(minLength: 8)
                Text("newExercise.summary \(viewModel.secondsPerCycle)")
                    .designFont(.subheadline, 15, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color(.fg2))
                    .accessibilityIdentifier("newExercise.summary")
            }
            VStack(spacing: 0) {
                ForEach(Array(NewExerciseViewModel.Field.allCases.enumerated()), id: \.element) { index, field in
                    if index > 0 { Rectangle().fill(Color(.line)).frame(height: 1) }
                    stepperRow(field, scale: scale)
                }
            }
            .background(Color(.surface))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func stepperRow(_ field: NewExerciseViewModel.Field, scale: DesignScale) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: ExerciseText.phaseName(field.phaseKind))
                .designFont(.body, 17, weight: .medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            stepButton(systemName: "minus", enabled: viewModel.canDecrease(field), scale: scale) {
                viewModel.decrease(field)
            }
            .accessibilityLabel(Text(LocalizedStringKey("newExercise.decrease.\(field.key)")))
            .accessibilityIdentifier("newExercise.decrease.\(field.key)")
            Text("newExercise.value \(viewModel.seconds(field))")
                .designFont(.body, 17, weight: .semibold)
                .monospacedDigit()
                .frame(minWidth: 52)
                .accessibilityIdentifier("newExercise.value.\(field.key)")
            stepButton(systemName: "plus", enabled: viewModel.canIncrease(field), scale: scale) {
                viewModel.increase(field)
            }
            .accessibilityLabel(Text(LocalizedStringKey("newExercise.increase.\(field.key)")))
            .accessibilityIdentifier("newExercise.increase.\(field.key)")
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(minHeight: scale(48, 88))
    }

    private func stepButton(
        systemName: String, enabled: Bool, scale: DesignScale, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.ring))
                .frame(width: scale(44, 76), height: scale(44, 76))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    private func addButton(scale: DesignScale) -> some View {
        Button {
            if let record = viewModel.makeRecord() {
                save(record)
                dismiss()
            }
        } label: {
            Text("newExercise.add")
                .designFont(.title3, 19, weight: .semibold)
                .foregroundStyle(Color(.bg))
                .frame(maxWidth: .infinity, minHeight: scale(54, 96))
                .background(Capsule().fill(Color(.fg)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.4)
        .padding(.top, 8)
        .accessibilityIdentifier("newExercise.addButton")
    }
}
