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

    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    // Cream sheet chrome — ink stroke (Photo + rename blocks; no beige leftover).
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                block("Pet") {
                    HStack {
                        TextField("Name", text: $draftName)
                            .onSubmit { applyRename() }
                        Button("Save") { applyRename() }
                            .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text("Age  \(store.pet.ageDays) DAYS")
                    Text(store.lovesSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if store.pets.count > 1 {
                    block("Active pet", footer: "Island and widgets follow the active pet.") {
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
                        .pickerStyle(.menu)
                    }
                }

                block("Sound", footer: "Care, ball, and Island cues. Mixes with Music (ambient). Mute anytime.") {
                    Toggle(
                        "Sound effects",
                        isOn: Binding(
                            get: { PetSound.shared.isEnabled },
                            set: { PetSound.shared.isEnabled = $0 }
                        )
                    )
                }

                block(
                    "Fireflies",
                    footer: store.firefliesUnlocked == 0
                        ? "Keep Feeling full for a day to unlock Fireflies."
                        : "Unlocked \(store.firefliesUnlocked) of 2. Soft room motes — cosmetic only."
                ) {
                    Toggle(
                        "Show fireflies",
                        isOn: Binding(
                            get: { store.showFireflies },
                            set: { store.setShowFireflies($0) }
                        )
                    )
                    .disabled(store.firefliesUnlocked == 0)
                }

                block("Room", footer: "Sun Nook, Moon Porch, Meadow Walk, Tide Glass, Skyline Dusk, Snow Porch, and Coral Shelf — all free. Widgets and the Island stay pet-forward.") {
                    Picker(
                        "Room",
                        selection: Binding(
                            get: { store.selectedScene },
                            set: { store.setScene($0) }
                        )
                    ) {
                        ForEach(PetRoomScene.availableInDisplayOrder) { scene in
                            Text(scene.displayName).tag(scene)
                        }
                    }
                    .pickerStyle(.menu)
                }

                block("Dynamic Island", footer: "Live Activity renews before the ~8h Island limit (≥7h end→request). Care actions update the Island when it’s on.") {
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
                }

                block("Pet Photo widget", footer: "Saved on-device in the App Group as pet-frame.jpg. The widget never uploads your photo.") {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Text("Choose pet frame photo")
                            .foregroundStyle(ink)
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
                }

                block("Pet Weather", footer: "Location is requested in the app only (When In Use). The weather widget reads the App Group cache and never prompts. Enable WeatherKit on the App ID on a Mac — see README.") {
                    Button {
                        Task {
                            await WeatherFetchService.shared.refresh()
                            weatherStatus = WeatherFetchService.shared.statusMessage
                        }
                    } label: {
                        Text("Update weather for widget")
                            .foregroundStyle(ink)
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
                }

                block("Home Screen widgets") {
                    Button("How to add widgets") {
                        showWidgetTip = true
                    }
                }

                block("Help", footer: "Shake to sleep. The sleep tile does the same thing.") {
                    Text("Shake your phone to tuck them in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                block("Reset", footer: "Clears name, meters, and inventory, then returns to onboarding.") {
                    Button("Reset pet…", role: .destructive) {
                        showResetConfirm = true
                    }
                }
                }
                .padding(16)
            }
        }
        .background(cream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
            Text("Long-press the Home Screen → tap + → search “Live Pet” or “Pet” → add Live Pet, Pet Clock, Pet Weather, Pet Day, Pet Note, or Pet Photo. Lock Screen: long-press → Customize → add Live Pet Lock Screen (mono pet + Feeling dots).")
        }
    }

    private func block<Content: View>(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(ink.opacity(0.55))
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            )
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

