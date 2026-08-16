import AppKit

@MainActor
enum ApplicationMenu {
    static func install(on application: NSApplication) {
        let mainMenu = make()
        application.mainMenu = mainMenu
        application.servicesMenu = mainMenu.item(withTitle: "DSH Desktop")?
            .submenu?
            .item(withTitle: "Services")?
            .submenu
    }

    static func make() -> NSMenu {
        let mainMenu = NSMenu(title: "Main Menu")
        mainMenu.addItem(submenuItem(title: "DSH Desktop", menu: applicationMenu()))
        mainMenu.addItem(submenuItem(title: "Edit", menu: editMenu()))
        return mainMenu
    }

    private static func applicationMenu() -> NSMenu {
        let menu = NSMenu(title: "DSH Desktop")
        menu.addItem(commandItem(
            title: "About DSH Desktop",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        ))
        menu.addItem(.separator())

        let services = NSMenu(title: "Services")
        menu.addItem(submenuItem(title: "Services", menu: services))
        menu.addItem(.separator())

        menu.addItem(commandItem(
            title: "Hide DSH Desktop",
            action: #selector(NSApplication.hide(_:)),
            key: "h"
        ))
        menu.addItem(commandItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            key: "h",
            modifiers: [.command, .option]
        ))
        menu.addItem(commandItem(
            title: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:))
        ))
        menu.addItem(.separator())
        menu.addItem(commandItem(
            title: "Quit DSH Desktop",
            action: #selector(NSApplication.terminate(_:)),
            key: "q"
        ))
        return menu
    }

    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")
        menu.addItem(commandItem(title: "Cut", action: #selector(NSText.cut(_:)), key: "x"))
        menu.addItem(commandItem(title: "Copy", action: #selector(NSText.copy(_:)), key: "c"))
        menu.addItem(commandItem(title: "Paste", action: #selector(NSText.paste(_:)), key: "v"))
        menu.addItem(.separator())
        menu.addItem(commandItem(title: "Select All", action: #selector(NSText.selectAll(_:)), key: "a"))
        return menu
    }

    private static func submenuItem(title: String, menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func commandItem(
        title: String,
        action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.target = nil
        return item
    }
}
