import SwiftUI
import PhotosUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var showResetConfirm = false
    @State private var showWidgetTip = false
    @State private var photoItem: PhotosPickerItem?
    @State private var photoStatus: String = ""
    @State private var weatherStatus: String = ""

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
                Text(store.lovesSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if store.pets.count > 1 {
                Section {
                    Picker(
                        "Active pet",
                        selection: Binding(
                            get: { store.pet.id },
                            set: { store.setActivePet(id: $0) }
                        )
                    ) {
                        ForEach(store.pets) { p in
                            Text(p.name + (p.petGlyph == "pip" ? " (Pip)" : " (\(p.growthStage.displayName))"))
                                .tag(p.id)
                        }
                    }
                } header: {
                    Text("Active pet")
                } footer: {
                    Text("Island and widgets follow the active pet.")
                }
            }

            Section {
                Toggle(
                    "Sound effects",
                    isOn: Binding(
                        get: { PetSound.shared.isEnabled },
                        set: { PetSound.shared.isEnabled = $0 }
                    )
                )
            } header: {
                Text("Sound")
            } footer: {
                Text("Care, ball, and Island cues. Mixes with Music (ambient). Mute anytime.")
            }

            Section {
                Toggle(
                    "Show fireflies",
                    isOn: Binding(
                        get: { store.showFireflies },
                        set: { store.setShowFireflies($0) }
                    )
                )
                .disabled(store.firefliesUnlocked == 0)
            } header: {
                Text("Fireflies")
            } footer: {
                Text(store.firefliesUnlocked == 0
                    ? "Keep Feeling full for a day to unlock Fireflies."
                    : "Unlocked \(store.firefliesUnlocked) of 2. Soft room motes — cosmetic only.")
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
                Text("Sun Nook, Moon Porch, Tide Glass, and Skyline Dusk. Widgets and the Island stay pet-forward.")
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

            Section {
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Choose pet frame photo", systemImage: "photo.on.rectangle")
                }
                if hasPetFrame {
                    Button("Remove frame photo", role: .destructive) {
                        removePetFrame()
                    }
                }
                if !photoStatus.isEmpty {
                    Text(photoStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Pet Photo widget")
            } footer: {
                Text("Saved on-device in the App Group as pet-frame.jpg. The widget never uploads your photo.")
            }

            Section {
                Button {
                    Task {
                        await WeatherFetchService.shared.refresh()
                        weatherStatus = WeatherFetchService.shared.statusMessage
                    }
                } label: {
                    Label("Update weather for widget", systemImage: "cloud.sun")
                }
                if let cache = WeatherCache.load(), cache.hasObservation, let temp = cache.displayTemperature {
                    Text("Cached: \(temp) \(cache.conditionLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !weatherStatus.isEmpty {
                    Text(weatherStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Pet Weather")
            } footer: {
                Text("Location is requested in the app only (When In Use). The weather widget reads the App Group cache and never prompts. Enable WeatherKit on the App ID on a Mac — see README.")
            }

            Section("Home Screen widgets") {
                Button("How to add widgets") {
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
        .onAppear {
            draftName = store.pet.name
            weatherStatus = WeatherFetchService.shared.statusMessage
        }
        .onChange(of: photoItem) { newItem in
            guard let newItem else { return }
            Task { await savePetFrame(from: newItem) }
        }
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
        .alert("Add Live Pet widgets", isPresented: $showWidgetTip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Long-press the Home Screen → tap + → search “Live Pet” or “Pet” → add Pet Feeling, Pet Clock, Pet Weather, Pet Day, Pet Note, or Pet Photo.")
        }
    }

    private var hasPetFrame: Bool {
        guard let url = AppGroup.petFrameURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    private func applyRename() {
        store.rename(draftName)
        draftName = store.pet.name
    }

    @MainActor
    private func savePetFrame(from item: PhotosPickerItem) async {
        do {
            guard let loaded = try await item.loadTransferable(type: RawImageTransfer.self) else {
                photoStatus = "Couldn’t read that photo"
                return
            }
            let data = loaded.data
            guard let url = AppGroup.petFrameURL else {
                photoStatus = "App Group container missing"
                return
            }
            // Re-encode as JPEG when possible for a stable pet-frame.jpg.
            let jpeg: Data
            #if canImport(UIKit)
            if let ui = UIImage(data: data), let encoded = ui.jpegData(compressionQuality: 0.85) {
                jpeg = encoded
            } else {
                jpeg = data
            }
            #else
            jpeg = data
            #endif
            try jpeg.write(to: url, options: .atomic)
            photoStatus = "Saved for Pet Photo widget"
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            photoStatus = "Save failed"
        }
    }

    private func removePetFrame() {
        guard let url = AppGroup.petFrameURL else { return }
        try? FileManager.default.removeItem(at: url)
        photoStatus = "Photo removed"
        WidgetCenter.shared.reloadAllTimelines()
    }
}

