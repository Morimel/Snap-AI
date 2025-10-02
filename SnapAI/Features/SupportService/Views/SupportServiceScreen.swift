//
//  SupportServiceScreen.swift
//  SnapAI
//
//  Created by Isa Melsov on 1/10/25.
//

import SwiftUI
import PhotosUI
import OSLog
import Foundation

struct Country: Identifiable, Hashable {
    let iso: String
    let name: String
    let dialCode: String
    var id: String { iso } // по одной записи на ISO
    var flag: String {
        iso.unicodeScalars.reduce("") { s, sc in
            guard let v = UnicodeScalar(127397 + Int(sc.value)) else { return s }
            return s + String(v)
        }
    }
}

private enum DialCodeFix {
    // спорные/нестандартные страны
    static let overrides: [String: String] = [
        "AX": "+358", // Åland
        "VA": "+39",  // Vatican фактически живёт на итальянском +39
        "EH": "+212", // Western Sahara -> Morocco
        "UM": "+1"    // US Outlying Islands -> NANP
    ]
}

enum CountryProvider {
    private static var cache: [Country]?
    
    static func invalidateCache() { cache = nil }

    // ВЫЗЫВАЙ отсюда (кэшированная обёртка)
    static func getAll() async -> [Country] {
        if let cache { return cache }
        let loaded = (try? await loadAll()) ?? []
        cache = loaded
        return loaded
    }

    // Грузим из REST Countries. Берём ТОЛЬКО root кода
    private struct RC: Decodable {
        struct Name: Decodable { let common: String }
        struct IDD: Decodable { let root: String?; let suffixes: [String]? }
        let cca2: String
        let name: Name
        let idd: IDD?
    }
    
    private static func primaryDialCode(for c: RC) -> String? {
        // 1) явные оверрайды
        if let o = DialCodeFix.overrides[c.cca2] { return o }

        // 2) если root пуст — попробуем суффикс как самостоятельный код (редко)
        guard let rawRoot = c.idd?.root, !rawRoot.isEmpty else {
            if let s = c.idd?.suffixes?.first, !s.isEmpty {
                let sDigits = s.filter(\.isNumber)
                return sDigits.isEmpty ? nil : "+" + sDigits
            }
            return nil
        }

        let root = rawRoot.trimmingCharacters(in: .whitespaces)
        let rootDigits = root.filter(\.isNumber).count

        // 3) NANP и +7 — не разворачиваем в area-codes
        if root == "+1" || root == "+7" { return root }

        // 4) Пытаемся собрать ИМЕННО страновой код (≤3 цифр суммарно)
        if let s = c.idd?.suffixes?.first, !s.isEmpty {
            let sDigits = s.filter(\.isNumber)

            // сперва пробуем 2 цифры (даёт +380, +971, +994 и т.п.)
            if sDigits.count >= 2, rootDigits + 2 <= 3 {
                return root + sDigits.prefix(2)
            }
            // потом 1 цифру (даёт +39, +44, +34 и т.д.)
            if sDigits.count >= 1, rootDigits + 1 <= 3 {
                return root + sDigits.prefix(1)
            }
            // если хвост короткий сам по себе (редкий кейс)
            if rootDigits + sDigits.count <= 3 {
                return root + sDigits
            }
        }

        // 5) иначе — корневой код уже полный (+358, +380, ...)
        return root
    }

    static func loadAll() async throws -> [Country] {
        let url = URL(string: "https://restcountries.com/v3.1/all?fields=cca2,name,idd")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode([RC].self, from: data)

        let loc = Locale.current
        var byISO: [String: Country] = [:]

        for c in decoded {
            guard let dial = primaryDialCode(for: c) else { continue }
            let name = loc.localizedString(forRegionCode: c.cca2) ?? c.name.common
            byISO[c.cca2] = Country(iso: c.cca2, name: name, dialCode: dial)
        }

        return Array(byISO.values)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

}

private struct CountryKey: Hashable {
    let iso: String
    let dial: String
}

// маленький хелпер

extension Array {
    func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>(), res: [Element] = []
        for e in self { if seen.insert(key(e)).inserted { res.append(e) } }
        return res
    }
}



struct CountryCodePicker: View {
    @Binding var selected: Country
    @State private var all: [Country] = []
    @State private var query = ""
    @State private var show = false
    @State private var loading = false

    var body: some View {
        Button {
            show = true
            if all.isEmpty { Task { await load() } }
        } label: {
            HStack(spacing: 6) {
                Text(selected.flag)
                Text(selected.dialCode)
                    .bold()
                    .foregroundStyle(AppColors.primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(AppColors.secondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $show) {
            NavigationStack {
                Group {
                    if loading {
                        ProgressView().padding()
                    } else {
                        List(filtered, id: \.id) { c in
                            Button {
                                selected = c; show = false
                            } label: {
                                HStack {
                                    Text(c.flag)
                                    Text(c.name)
                                        .foregroundStyle(AppColors.text)      // читаемое имя
                                    Spacer()
                                    Text(c.dialCode)
                                        .foregroundStyle(AppColors.primary)   // код — зелёный
                                }
                            }
                            .listRowBackground(AppColors.surface.opacity(0.92))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)            // убираем системный фон
                        .background(AppColors.surface)               // фон под списком
                        .listRowSeparatorTint(AppColors.text.opacity(0.12))
                    }
                }
                .tint(AppColors.primary)
            }
            .presentationBackground(AppColors.surface)
        }
    }

    private func load() async {
        loading = true
        do { all = try await CountryProvider.loadAll() }
        catch { print("Country load error:", error) }
        loading = false
    }

    private var filtered: [Country] {
        guard !query.isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) || $0.dialCode.contains(q) || $0.iso.lowercased().contains(q)
        }
    }
}


// MARK: - Model
struct SupportTicket {
    var name: String
    var country: Country
    var phone: String
    var message: String
    var image: UIImage?
}

// MARK: - View
struct SupportFormView: View {
    var onSubmit: (SupportTicket) -> Void = { ticket in
        print("Submitted: \(ticket.name) \(ticket.country.dialCode) \(ticket.phone)")
    }

    private let log = Logger(subsystem: "com.snapai.app", category: "SupportForm")
    
    // State
    @State private var name: String = ""
    @State private var country: Country = {
        let nameUS = Locale.current.localizedString(forRegionCode: "US") ?? "United States"
        return Country(iso: "US", name: nameUS, dialCode: "+1")
    }()
    @State private var phone: String = ""
    @State private var message: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    
    
    @State private var sending = false
    @State private var showAlert = false
    @State private var alertText = ""


    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    enum Field { case name, phone, message }

    var body: some View {
        NavigationStack {
            ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Name
                    // Name
                    FieldContainer {
                        HStack(spacing: 10) {
                            Image(systemName: "person.text.rectangle")
                                .foregroundStyle(AppColors.primary)

                            ZStack(alignment: .leading) {
                                // плейсхолдер
                                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Your name")
                                        .foregroundStyle(AppColors.text.opacity(0.75))
                                        .allowsHitTesting(false)
                                }

                                TextField("", text: $name)
                                    .foregroundStyle(AppColors.primary)
                                    .tint(AppColors.primary)
                                    .textContentType(.name)
                                    .textInputAutocapitalization(.words)
                                    .submitLabel(.next)
                                    .focused($focusedField, equals: .name)
                                    .onSubmit { focusedField = .phone }
                            }
                        }
                    }

                    // Phone
                    FieldContainer {
                        HStack(spacing: 10) {
                            CountryCodePicker(selected: $country)
                            Divider().frame(height: 22)

                            ZStack(alignment: .leading) {
                                if phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Phone number")
                                        .foregroundStyle(AppColors.text.opacity(0.75))
                                        .allowsHitTesting(false)
                                }

                                TextField("", text: $phone)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .foregroundStyle(AppColors.primary)
                                    .tint(AppColors.primary)
                                    .focused($focusedField, equals: .phone)
                            }
                        }
                    }


                    
                    // Message
                    EditorContainer(text: $message,
                                    placeholder: "Tell us what happened…",
                                    minHeight: 140)
                    .focused($focusedField, equals: .message)
                    
                    // Photo attach / preview
                    AttachmentPicker(photoItem: $photoItem, image: $pickedImage)
                    
                    // Send button
                    Button(action: submit) {
                                            Text(sending ? "Sending..." : "Send")
                                                .font(.headline)
                                                .frame(maxWidth: .infinity, minHeight: 52)
                                                .foregroundColor(.white)
                                                .background((isValid && !sending) ? AppColors.primary : AppColors.primary.opacity(0.4))
                                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isValid)
                    .padding(.top, 6)
                    if !isValid {
                        Text("name: \(name.trimmed.count)  |  msg: \(message.trimmed.count)  |  phoneDigits: \(phone.onlyDigitsCount)")
                            .font(.caption2)
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Please fill all required fields to send your message.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                            
                        if sending {
                            Color.black.opacity(0.15).ignoresSafeArea()
                            ProgressView("Sending...")
                                .padding(20)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .zIndex(100)
                        }
                    }
                }
                .padding(16)
                
                
            }
            .scrollDismissesKeyboard(.interactively) // свайпом вниз
            .hideKeyboardOnTap()

            .navigationBarBackButtonHidden(true)
            .background(AppColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        AppImages.ButtonIcons.arrowRight
                            .resizable()
                            .scaledToFill()
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(180))
                            .padding(12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Text("Support")
                        .foregroundStyle(AppColors.primary)
                        .bold()
                        .font(.largeTitle)
                }
                
            }
        }
            .alert("Support", isPresented: $showAlert) {
              Button("OK", role: .cancel) {}
            } message: { Text(alertText) }
        }
    }
    @MainActor
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    private var isValid: Bool {
            let nOK = name.trimmed.count >= 2
            let mOK = message.trimmed.count >= 10
            let totalDigits = (country.dialCode + phone).filter(\.isNumber).count
            let pOK = totalDigits >= 10
            return nOK && mOK && pOK
        }

    private func submit() {
        // защита от дабл-тапа
        guard isValid, !sending else { return }
        
        let fullPhone = normalizedPhone(country: country, raw: phone)
        let hasImage = pickedImage != nil
        
        // 🔎 логируем ввод перед отправкой
        log.info("Submit tapped. name: \(self.name, privacy: .public), phone: \(fullPhone, privacy: .public), msg_len: \(self.message.trimmed.count), hasImage: \(hasImage, privacy: .public)")
        if let img = pickedImage, let data = img.jpegData(compressionQuality: 0.8) {
            log.debug("Image JPEG size: \(data.count, privacy: .public) bytes")
        }
        
        Task { @MainActor in
            sending = true
            defer { sending = false }   // вернём кнопку в нормальное состояние
            
            do {
                _ = try await AuthAPI.shared.createReport(
                    name: name.trimmed,
                    phoneNumber: fullPhone,
                    comment: message.trimmed,
                    image: pickedImage   // multipart; можно nil
                )
                
                // 🔎 успех
                log.info("Report sent successfully")
                
                // ✅ очищаем поля и фото
                name = ""
                phone = ""
                message = ""
                pickedImage = nil
                photoItem = nil
                focusedField = nil
                
                // UX: показать подтверждение
                alertText = "Sent! Our support will contact you soon."
                showAlert = true
            } catch let APIError.validation(map) {
                let msg = map.values.first?.first ?? "Validation error"
                log.error("Validation failed: \(msg, privacy: .public)")
                alertText = msg
                showAlert = true
            } catch {
                log.error("Report send failed: \(error.localizedDescription, privacy: .public)")
                alertText = error.localizedDescription
                showAlert = true
            }
        }
    }

}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var onlyDigitsCount: Int {
        unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }.count
    }
}
// MARK: - Components

/// Glass-style container for text fields
struct FieldContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 12, y: 6)

            HStack { content }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
    }
}

private func normalizedPhone(country: Country, raw: String) -> String {
    let digits = raw.filter(\.isNumber)               // только цифры из поля
    let code = country.dialCode                       // вроде "+1", "+7", "+358"…
    return code + digits
}

private func jpegBase64(_ image: UIImage?) -> String? {
    guard let image, let data = image.jpegData(compressionQuality: 0.8) else { return nil }
    return data.base64EncodedString()                 // при необходимости можно вернуть "data:image/jpeg;base64," + …
}

/// TextEditor с плейсхолдером и тем же стилем контейнера
struct EditorContainer: View {
    @Binding var text: String
    var placeholder: String
    var minHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            FieldContainer { EmptyView() }
                .frame(minHeight: minHeight)

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(AppColors.primary)      // цвет введённого текста
                .tint(AppColors.primary)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .overlay(alignment: .topLeading) {
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(placeholder)
                            .foregroundStyle(AppColors.text.opacity(0.75)) // плейсхолдер темнее
                            .padding(.horizontal, 22)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}


/// Country dial code picker
struct CountryCodeMenu: View {
    @Binding var selected: Country
    @State private var all: [Country] = []

    var body: some View {
        Menu {
            ForEach(all) { c in
                Button { selected = c } label: {
                    Label {
                        Text("\(c.name)  \(c.dialCode)")
                    } icon: {
                        FlagIcon(iso: c.iso, size: 18)  // 👈 картинка с фолбэком
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                FlagIcon(iso: selected.iso, size: 18)
                Text(selected.dialCode).bold().foregroundStyle(AppColors.primary)
                Image(systemName: "chevron.down").font(.caption).foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .task {
            if all.isEmpty {
                CountryProvider.invalidateCache()
                all = await CountryProvider.getAll()
                if let match = all.first(where: { $0.iso == selected.iso }) {
                    selected = match
                }
            }
        }
    }
}

struct FlagIcon: View {
    let iso: String
    var size: CGFloat = 18

    var body: some View {
        AsyncImage(url: flagURL(iso: iso, px: Int(size*2))) { phase in
            if case .success(let img) = phase {
                img.resizable().scaledToFill()
            } else {
                Text(emojiFlag(iso))           // fallback
                    .font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.2).stroke(.black.opacity(0.06), lineWidth: 1))
    }

    private func flagURL(iso: String, px: Int) -> URL? {
        URL(string: "https://flagcdn.com/w\(px)/\(iso.lowercased()).png") // компактные PNG
    }

    private func emojiFlag(_ iso: String) -> String {
        iso.unicodeScalars.reduce("") { s, sc in
            guard let v = UnicodeScalar(127397 + Int(sc.value)) else { return s }
            return s + String(v)
        }
    }
}

/// Photo attach + preview with remove
struct AttachmentPicker: View {
    @Binding var photoItem: PhotosPickerItem?
    @Binding var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 12) {
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Attach photo", systemImage: "paperclip")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppColors.secondary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                // 👉 полностью отключаем picker, когда фото уже есть,
                // чтобы он не перекрывал "Remove"
                .disabled(image != nil)
                .opacity(image == nil ? 1 : 0.5)
                .onChange(of: photoItem?.itemIdentifier) { _ in
                    guard let item = photoItem else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let ui = UIImage(data: data) {
                            await MainActor.run { image = ui }
                        }
                    }
                }
            }

            if let ui = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 6)

                    Button(action: clearPhoto) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white, .black.opacity(0.4))
                            .font(.title3)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.scale)
            }
        }
       
    }

    @MainActor
    private func clearPhoto() {
        withAnimation(.easeInOut) {
            image = nil
            photoItem = nil
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SupportFormView()
    }
}
