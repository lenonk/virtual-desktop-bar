#include <ranges>

#include <QDBusMetaType>

#include "VirtualDesktopBar.hpp"

void
registerKWinDesktopMetaTypes() {
    static bool registered {false};
    if (registered) return;

    qDebug() << "*************** Registering KWinDesktop meta-types ******************";
    qRegisterMetaType<KWinDesktop>("KWinDesktop");
    qRegisterMetaType<QList<KWinDesktop>>("QList<KWinDesktop>");
    qDBusRegisterMetaType<QList<KWinDesktop>>();
    qDBusRegisterMetaType<KWinDesktop>();
}

QDBusArgument &operator <<(QDBusArgument &argument, const KWinDesktop &desktop) {
    argument.beginStructure();
    argument << desktop.id << desktop.uuid << desktop.name;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator >>(const QDBusArgument &argument, KWinDesktop &desktop) {
    argument.beginStructure();
    argument >> desktop.id >> desktop.uuid >> desktop.name;
    argument.endStructure();
    return argument;
}

VirtualDesktopBar::VirtualDesktopBar(QObject *parent) : QObject(parent) {
    registerKWinDesktopMetaTypes();
}

VirtualDesktopBar::~VirtualDesktopBar() {
    for (const auto interface : m_interfaces | std::views::values) {
        delete interface;
    }

    m_interfaces.clear();
}

QDBusInterface *
VirtualDesktopBar::createInterface(const QString &service, const QString &path, const QString &interface,
    const QDBusConnection &busType) {
    const QString key = service + path + interface;

    if (m_interfaces.contains(key)) {
        return m_interfaces[key];
    }

    const auto iface = new QDBusInterface(service, path, interface, busType, this);

    if (!iface->isValid()) {
        qWarning() << std::format("Failed to create interface {} for {}:{}", service.toStdString(),
            path.toStdString(), interface.toStdString());
        delete iface;
        return nullptr;
    }

    m_interfaces[key] = iface;
    return iface;
}

QList<KWinDesktop>
getKWinDesktops() {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        DBus::Services::KWin,
        DBus::Paths::VDManager,
        QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("Get"));

    msg << DBus::Interfaces::VDManager << QStringLiteral("desktops");

    QDBusMessage reply = QDBusConnection::sessionBus().call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to get desktops property";
        return {};
    }

    const QVariant variant = reply.arguments().at(0);
    const auto dbusVar = variant.value<QDBusVariant>();

    auto argument = dbusVar.variant().value<QDBusArgument>();

    QList<KWinDesktop> desktops;
    argument.beginArray();
    while (!argument.atEnd()) {
        KWinDesktop desktop;
        argument >> desktop;
        desktops.append(desktop);
    }
    argument.endArray();

    return desktops;
}

QVariantList
VirtualDesktopBar::requestDesktopInfoList() {
   QVariantList desktopInfoList;

    const auto dbus = createInterface(DBus::Services::KWin, DBus::Paths::VDManager, DBus::Interfaces::VDManager);
    if (!dbus) {
        qWarning() << "Failed to connect to VirtualDesktopManager interface";
        return desktopInfoList;
    }

    QVariant variant = dbus->property("count");

   if (const auto desktop_count = variant.isValid() ? variant.toInt() : 0; desktop_count <= 0) {
        qWarning() << std::format("Invalid desktop count: {}", desktop_count);
        return desktopInfoList;
    }

    variant = dbus->property("current");
    const auto curr_desktop_uuid = variant.isValid() ? variant.toString() : QString();

    // NOTE: Have to do this because dbus->property("desktops") won't deserialize the data
   for (const auto desktops = getKWinDesktops(); const auto &desktop : desktops) {
        QVariantMap desktop_info;

        desktop_info[QStringLiteral("id")] = desktop.id;
        desktop_info[QStringLiteral("uuid")] = desktop.uuid;
        desktop_info[QStringLiteral("name")] = desktop.name;
        desktop_info[QStringLiteral("is_current")] = desktop.uuid == curr_desktop_uuid;

        // For now, set these as placeholders until we implement window tracking
        desktop_info[QStringLiteral("is_empty")] = true;
        desktop_info[QStringLiteral("is_visible")] = true;
        desktop_info[QStringLiteral("window_name_list")] = QStringList();

        desktopInfoList.append(desktop_info);
    }

    return desktopInfoList;
}
