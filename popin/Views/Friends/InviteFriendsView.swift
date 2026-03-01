import SwiftUI

struct InviteFriendsView: View {
    let userId: String
    let viewModel: FriendsViewModel

    @State private var contactsService = ContactsService()
    @State private var searchText = ""
    @State private var hasMatched = false
    @State private var smsRecipient: String?
    @State private var showSMS = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch contactsService.authStatus {
                case .notDetermined:
                    requestAccessView
                case .authorized:
                    contactsList
                case .denied, .restricted:
                    deniedView
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showSMS) {
                if let phone = smsRecipient {
                    SMSInviteView(
                        recipientPhone: phone,
                        userId: userId
                    )
                }
            }
        }
    }

    // MARK: - Request Access

    private var requestAccessView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Find Friends on PopIn")
                .font(.title3.bold())

            Text("We'll check your contacts to find\npeople already on PopIn")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    let granted = await contactsService.requestAccess()
                    if granted {
                        await contactsService.fetchContacts()
                        matchContacts()
                    }
                }
            } label: {
                Text("Allow Contact Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    // MARK: - Denied

    private var deniedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Contact Access Denied")
                .font(.title3.bold())

            Text("Enable contact access in Settings\nto find friends on PopIn")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }

    // MARK: - Contacts List

    private var contactsList: some View {
        List {
            if contactsService.isLoading || viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Finding friends...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Matched contacts (already on PopIn)
            if !viewModel.matchedContacts.isEmpty {
                Section("On PopIn") {
                    ForEach(filteredMatched) { contact in
                        HStack(spacing: 12) {
                            Text(contact.displayEmoji)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("Already on PopIn")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }

                            Spacer()

                            let alreadyFriend = viewModel.friends.contains { $0.userId == contact.userId }

                            if alreadyFriend {
                                Text("Friends")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Button {
                                    viewModel.sendFriendRequest(
                                        from: userId,
                                        to: contact.userId
                                    )
                                } label: {
                                    Text("Add")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(.orange)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Contacts not on PopIn
            if !filteredContacts.isEmpty {
                Section("Invite to PopIn") {
                    ForEach(filteredContacts) { contact in
                        HStack(spacing: 12) {
                            if let data = contact.thumbnailData,
                               let uiImage = UIImage(data: data)
                            {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.fullName)
                                    .font(.subheadline.weight(.medium))
                                Text(contact.phoneNumbers.first ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                smsRecipient = contact.phoneNumbers.first
                                showSMS = true
                            } label: {
                                Text("Invite")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .onAppear {
            if !hasMatched {
                Task {
                    await contactsService.fetchContacts()
                    matchContacts()
                }
            }
        }
    }

    // MARK: - Helpers

    private func matchContacts() {
        guard !contactsService.allPhoneNumbers.isEmpty else { return }
        hasMatched = true
        viewModel.matchContacts(
            userId: userId,
            phoneNumbers: contactsService.allPhoneNumbers
        )
    }

    private var filteredMatched: [MatchedContact] {
        if searchText.isEmpty { return viewModel.matchedContacts }
        return viewModel.matchedContacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredContacts: [ContactsService.ContactEntry] {
        // Only show contacts that aren't matched (not on PopIn)
        let matchedPhones = Set(viewModel.matchedContacts.map(\.phoneNumber))
        let unmatched = contactsService.contacts.filter { contact in
            !contact.phoneNumbers.contains(where: { matchedPhones.contains($0) })
        }

        if searchText.isEmpty { return unmatched }
        return unmatched.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }
}
