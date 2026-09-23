import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var showResetConfirm = false
    @State private var showWidgetTip = false

    var body: some View {
        Form {
            Section("Pet") {
                HStack {
                    TextField("Name", text: $draftName)
                        .onSubmit { applyRename() }
                    Button("Save") { applyRename() }
                        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                LabeledContent("Age", value: "\(store.pet.ageDays) DAYS")
            }

            Section {
                Picker(
                    "Room",
                    selection: Binding(
                        get: { store.selectedScene },
                        set: { store.setScene($0) }
                    )
                ) {
                    ForEach(PetRoomScene.allCases) { scene in
                        Text(scene.displayName).tag(scene)
                    }
                }
            } header: {
                Text("Room")
            } footer: {
                Text("Sun Nook by day, Moon Porch for a cool evening porch. Widgets and the Island stay pet-forward.")
            }

            Section {
                Toggle(
                    "Show on Dynamic Island",
                    isOn: Binding(
                        get: { activityManager.isActivityActive },
                        set: { on in
                            if on {
                                activityManager.start(pet: store.pet)
                            } else {
                                activityManager.end()
                            }
                        }
                    )
                )
                .disabled(!activityManager.areActivitiesEnabled && !activityManager.isActivityActive)

                if !activityManager.areActivitiesEnabled {
                    Text("Turn on Live Activities in iOS Settings → Live Pet to use the Island.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = activityManager.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Dynamic Island")
            } footer: {
                Text("Live Activity renews before the ~8h Island limit (≥7h end→request). Care actions update the Island when it’s on.")
            }

            Section("Home Screen widget") {
                Button("How to add the widget") {
                    showWidgetTip = true
                }
            }

            Section {
                Label("Shake your phone to tuck them in.", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            } header: {
                Text("Help")
            } footer: {
                Text("Shake → sleep. Fallback: Sleep / Tuck in on Pet Home, or Lull from the Dynamic Island (iOS 17+).")
            }

            Section {
                Button("Reset pet…", role: .destructive) {
                    showResetConfirm = true
                }
            } footer: {
                Text("Clears name, meters, and inventory, then returns to onboarding.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draftName = store.pet.name }
        .alert("Reset pet?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                activityManager.end()
                store.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can’t be undone. You’ll name a new pet.")
        }
        .alert("Add Live Pet widget", isPresented: $showWidgetTip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Long-press the Home Screen → tap + → search “Live Pet” → add the small or medium widget.")
        }
    }

    private func applyRename() {
        store.rename(draftName)
        draftName = store.pet.name
    }
}
