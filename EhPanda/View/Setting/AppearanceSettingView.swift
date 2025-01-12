//
//  AppearanceSettingView.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 3/01/18.
//

import SwiftUI

struct AppearanceSettingView: View, StoreAccessor {
    @EnvironmentObject var store: Store
    @State private var isNavLinkActive = false

    private var settingBinding: Binding<Setting> {
        $store.appState.settings.setting
    }
    private var selectedIcon: IconType {
        store.appState.settings.setting.appIconType
    }
    private var iconType: IconType {
        var alterName: String?
        AppUtil.dispatchMainSync {
            alterName = UIApplication.shared.alternateIconName
        }

        guard let iconName = alterName,
              let selection = IconType.allCases.filter({
                  iconName.contains($0.fileName ?? "")
              }).first else { return .default }
        return selection
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Theme")
                    Spacer()
                    Picker(
                        selection: settingBinding.preferredColorScheme,
                        label: Text(setting.preferredColorScheme.rawValue.localized),
                        content: {
                            ForEach(PreferredColorScheme.allCases) { colorScheme in
                                Text(colorScheme.rawValue.localized).tag(colorScheme)
                            }
                        }
                    )
                }
                .pickerStyle(.menu)
                ColorPicker("Tint Color", selection: settingBinding.accentColor)
                Button("App Icon") {
                    isNavLinkActive.toggle()
                }
                .foregroundStyle(.primary).withArrow()
            }
            Section("List".localized) {
                HStack {
                    Text("Display mode")
                    Spacer()
                    Picker(
                        selection: settingBinding.listMode,
                        label: Text(setting.listMode.rawValue.localized),
                        content: {
                            ForEach(ListMode.allCases) { listMode in
                                Text(listMode.rawValue.localized).tag(listMode)
                            }
                        }
                    )
                }
                .pickerStyle(.menu)
                Toggle(isOn: settingBinding.showsSummaryRowTags) {
                    Text("Shows tags in list")
                }
                HStack {
                    Text("Maximum number of tags")
                    Spacer()
                    Picker(
                        selection: settingBinding.summaryRowTagsMaximum,
                        label: Text("\(setting.summaryRowTagsMaximum)")
                    ) {
                        Text("Infinity").tag(0)
                        ForEach(Array(stride(from: 5, through: 20, by: 5)), id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .disabled(!setting.showsSummaryRowTags)
            }
        }
        .background {
            NavigationLink(
                destination: SelectAppIconView(selectedIcon: selectedIcon) {
                    store.dispatch(.setAppIconType(iconType))
                },
                isActive: $isNavLinkActive, label: {}
            )
        }
        .navigationBarTitle("Appearance")
    }
}

// MARK: SelectAppIconView
private struct SelectAppIconView: View {
    private let selectedIcon: IconType
    private let selectAction: () -> Void

    init(selectedIcon: IconType, selectAction: @escaping () -> Void) {
        self.selectedIcon = selectedIcon
        self.selectAction = selectAction
    }

    var body: some View {
        Form {
            Section {
                ForEach(IconType.allCases) { icon in
                    AppIconRow(
                        iconName: icon.iconName,
                        iconDesc: icon.rawValue,
                        isSelected: icon == selectedIcon
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { setIcon(icon) }
                }
            }
        }
        .onAppear(perform: selectAction)
    }

    private func setIcon(_ icon: IconType) {
        UIApplication.shared.setAlternateIconName(icon.fileName) { error in
            if let error = error {
                HapticUtil.generateNotificationFeedback(style: .error)
                Logger.error(error)
            }
            selectAction()
        }
    }
}

// MARK: AppIconRow
private struct AppIconRow: View {
    private let iconName: String
    private let iconDesc: String
    private let isSelected: Bool

    init(iconName: String, iconDesc: String, isSelected: Bool) {
        self.iconName = iconName
        self.iconDesc = iconDesc
        self.isSelected = isSelected
    }

    var body: some View {
        HStack {
            Image(iconName).resizable().scaledToFit()
                .frame(width: 60, height: 60).cornerRadius(12)
                .padding(.vertical, 10).padding(.trailing, 20)
            Text(iconDesc.localized)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .opacity(isSelected ? 1 : 0).foregroundStyle(.tint).imageScale(.large)
        }
    }
}

// MARK: Definition
enum IconType: String, Codable, Identifiable, CaseIterable {
    var id: Int { hashValue }

    case normal = "Normal"
    case `default` = "Default"
    case weird = "Weird"
}

extension IconType {
    var iconName: String {
        switch self {
        case .normal:
            return "AppIcon_Normal"
        case .default:
            return "AppIcon_Default"
        case .weird:
            return "AppIcon_Weird"
        }
    }
    var fileName: String? {
        switch self {
        case .default:
            return nil
        default:
            return rawValue
        }
    }
}
