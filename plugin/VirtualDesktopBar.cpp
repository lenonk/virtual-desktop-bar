#include <ranges>

#include <QString>
#include <QDBusMetaType>
#include <QDBusReply>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QScreen>
#include <QCoreApplication>
#include <QDBusConnectionInterface>

#include <KService>
#include <PlasmaActivities/Consumer>

#include "VirtualDesktopBar.hpp"

#include <memory>

#define QSL(str) QStringLiteral(str)

void
registerKWinDesktopMetaTypes() {
    static bool registered {false};
    if (registered) return;

    qDebug() << "*************** Registering KWinDesktop meta-types ******************";
    qRegisterMetaType<KWin::KWinDesktopData>("KWin::DBusDesktopDataStruct");
    qRegisterMetaType<KWin::KWinDesktopDataList>("KWin::DBusDesktopDataVector");
    qDBusRegisterMetaType<KWin::KWinDesktopData>();
    qDBusRegisterMetaType<KWin::KWinDesktopDataList>();

    registered = true;
}

VirtualDesktopBar::VirtualDesktopBar(QObject *parent) : QObject(parent) {
    registerKWinDesktopMetaTypes();
    connectToDBusSignals();
}

VirtualDesktopBar::~VirtualDesktopBar() {
}

void
VirtualDesktopBar::connectToDBusSignals() {
    QDBusConnection::sessionBus().connect(DBus::Services::KWin, DBus::Paths::VDManager,
        DBus::Interfaces::VDManager, QSL("desktopCreated"), this,
        SLOT(onDesktopCreated(QString,KWin::KWinDesktopData)));

    QDBusConnection::sessionBus().connect(DBus::Services::KWin, DBus::Paths::VDManager,
        DBus::Interfaces::VDManager, QSL("desktopDataChanged"), this,
        SLOT(onDesktopDataChanged(QString,KWin::KWinDesktopData)));

    QDBusConnection::sessionBus().connect(DBus::Services::KWin, DBus::Paths::VDManager,
        DBus::Interfaces::VDManager, QSL("desktopRemoved"), this, SLOT(onDesktopRemoved(QString)));

    QDBusConnection::sessionBus().connect(DBus::Services::KWin, DBus::Paths::VDManager,
        DBus::Interfaces::VDManager, QSL("currentChanged"), this, SLOT(onCurrentChanged(QString)));
}

QDBusInterface *
VirtualDesktopBar::createInterface(const QString &service, const QString &path, const QString &interface,
    const QDBusConnection &busType) {
    const QString key = service + path + interface;

    const auto iface = new QDBusInterface(service, path, interface, busType, this);

    if (!iface->isValid()) {
        qWarning() << QSL("Failed to create interface %1 for %2:%3").arg(service, path, interface);
        delete iface;
        return nullptr;
    }

    return iface;
}

QVariantList
VirtualDesktopBar::requestDesktopInfoList() {
    auto getDesktopsProperty = [this]() -> KWin::KWinDesktopDataList {
        QDBusMessage msg = QDBusMessage::createMethodCall( DBus::Services::KWin, DBus::Paths::VDManager,
           QSL("org.freedesktop.DBus.Properties"), QSL("Get"));

        msg << DBus::Interfaces::VDManager << QSL("desktops");

        QDBusMessage reply = QDBusConnection::sessionBus().call(msg);
        if (reply.type() == QDBusMessage::ErrorMessage) {
            qWarning() << "Failed to get desktops property";
            return {};
        }

        const QVariant variant = reply.arguments().at(0);
        const auto dbusVar = variant.value<QDBusVariant>();

        auto argument = dbusVar.variant().value<QDBusArgument>();

        KWin::KWinDesktopDataList desktops;
        argument.beginArray();
        while (!argument.atEnd()) {
            KWin::KWinDesktopData desktop;
            argument >> desktop;
            desktops.append(desktop);
        }
        argument.endArray();

        return desktops;
    };

    const auto dbus = createInterface(DBus::Services::KWin, DBus::Paths::VDManager, DBus::Interfaces::VDManager);
    if (!dbus) {
        qWarning() << "Failed to connect to VirtualDesktopManager interface";
        return {};
    }

    // Virtual desktop count
    QVariant variant = dbus->property("count");

   if (const auto desktop_count = variant.isValid() ? variant.toInt() : 0; desktop_count <= 0) {
        qWarning() << QSL("Invalid desktop count: %1").arg(desktop_count);
        return {};
    }

    // Current virtual desktop
    variant = dbus->property("current");
    const auto curr_desktop_uuid = variant.isValid() ? variant.toString() : QString();

    // NOTE: Have to call getDesktopsProprty() (KWinDesktop.h) because dbus->property("desktops") won't deserialize the
    // data due to signature mismatch.  Maybe one day I'll be able to unconnent the much cleaner code below.
   QVariantList desktopInfoList;
   for (const auto &[id, uuid, name] : getDesktopsProperty()) {
        QVariantMap desktop_info;

        desktop_info[QSL("id")] = id;
        desktop_info[QSL("uuid")] = uuid;
        desktop_info[QSL("name")] = name;
        desktop_info[QSL("is_current")] = uuid == curr_desktop_uuid;

        // For now, set these as placeholders until we implement window tracking
        desktop_info[QSL("is_empty")] = true;
        desktop_info[QSL("is_visible")] = true;

        desktopInfoList.append(desktop_info);
    }

    return desktopInfoList;
}

// This doesn't work because whoever is responsible for org.kde.KWin.VirtualDesktopManager fucked up.
// The desktops property is declared with signature a(iss), but actually provides data with signature
// a(uss).  This makes it impossible to register a type that works with qDBusRegisterMetaType.
// QVariantList
// VirtualDesktopBar::requestDesktopInfoList() {
//     const auto dbus = createInterface(DBus::Services::KWin, DBus::Paths::VDManager, DBus::Interfaces::VDManager);
//     if (!dbus) {
//         qWarning() << "Failed to connect to VirtualDesktopManager interface";
//         return {};
//     }
//
//     // Virtual desktop count
//     QVariant variant = dbus->property("count");
//
//     if (const auto desktop_count = variant.isValid() ? variant.toInt() : 0; desktop_count <= 0) {
//         qWarning() << QSL("Invalid desktop count: %1").arg(desktop_count);
//         return {};
//     }
//
//     // Current virtual desktop
//     variant = dbus->property("current");
//     const auto curr_desktop_uuid = variant.isValid() ? variant.toString() : QString();
//
//     // List of all desktops
//     variant = dbus->property("desktops");
//     if (!variant.isValid()) {
//         qWarning() << "Failed to get desktops property. D-Bus error: " << dbus->lastError().message();
//         return {};
//     }
//
//     const auto desktops_arg = variant.value<QDBusArgument>();
//     if (desktops_arg.currentType() != QDBusArgument::ArrayType) {
//         qWarning() << "Invalid desktops property type.  != QDbusArgument::ArrayType";
//         return {};
//     }
//
//     const auto desktops = variant.value<QList<KWin::KWinDesktopData>>();
//     QVariantList desktopInfoList;
//     for (const auto &[id, uuid, name] : desktops) {
//         QVariantMap desktop_info;
//
//         desktop_info[QStringLiteral("id")] = id;
//         desktop_info[QStringLiteral("uuid")] = uuid;
//         desktop_info[QStringLiteral("name")] = name;
//         desktop_info[QStringLiteral("is_current")] = uuid == curr_desktop_uuid;
//
//         // For now, set these as placeholders until we implement window tracking
//         desktop_info[QStringLiteral("is_empty")] = true;
//         desktop_info[QStringLiteral("is_visible")] = true;
//         desktop_info[QStringLiteral("window_name_list")] = QStringList();
//
//         desktopInfoList.append(desktop_info);
//     }
//
//     delete dbus;
//     return desktopInfoList;
// }

bool
VirtualDesktopBar::createDesktop(quint32 index, const QString &name) {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::VDManager,
       DBus::Interfaces::VDManager, QSL("createDesktop"));

    msg << index << name;

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << QSL("Failed to create desktop: Name: %1, Index: %2").arg(name, index);
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::removeDesktop(QString id) {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::VDManager,
       DBus::Interfaces::VDManager, QSL("removeDesktop"));

    msg << id;

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << QSL("Failed to remove desktop: Id: %1").arg(id);
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::setDesktopName(QString id, QString name) {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::VDManager,
       DBus::Interfaces::VDManager, QSL("setDesktopName"));

    msg << id << name;

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to set desktop name";
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::setCurrentDesktop(const qint32 number) {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::KWin,
       DBus::Interfaces::KWin, QSL("setCurrentDesktop"));

    msg << number;

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to set current desktop";
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::nextDesktop() {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::KWin,
       DBus::Interfaces::KWin, QSL("nextDesktop"));

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to call nextDesktop()";
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::previousDesktop() {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::KWin,
       DBus::Interfaces::KWin, QSL("previousDesktop"));

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to call previousDesktop()";
        return false;
    }

    return true;
}

QString
VirtualDesktopBar::getIconFromDesktopFile(const QString &desktopFile) {
    QString serviceName = desktopFile;
    if (serviceName.endsWith(QSL(".desktop"))) {
        serviceName.chop(8);
    }

    KService::Ptr service = KService::serviceByDesktopName(serviceName);
    if (service) {
        return service->icon();
    }

    return QSL("application-x-executable");
}

QString
VirtualDesktopBar::getCurrentActivityId() {
    KActivities::Consumer consumer;
    return consumer.currentActivity();
}

QString
VirtualDesktopBar::getActivityName(const QString activityId) {
    KActivities::Consumer consumer;
    const KActivities::Info activityInfo(activityId);
    return activityInfo.name();
}

QPoint
VirtualDesktopBar::getCursorPosition() const {
    return QCursor::pos();
}

QPoint
VirtualDesktopBar::getRelativeCursorPosition() const {
    const auto globalPos = QCursor::pos();
    auto currentScreen = QGuiApplication::screenAt(globalPos);

    if (!currentScreen) {
        currentScreen = QGuiApplication::primaryScreen();
    }

    if (currentScreen) {
        const auto screenGeometry = currentScreen->geometry();

        return QPoint(globalPos.x() - screenGeometry.x(),
                     globalPos.y() - screenGeometry.y());
    }

    return globalPos;
}
QSize
VirtualDesktopBar::getCursorSize() const {
    const auto currentCursor = QGuiApplication::overrideCursor() ? *QGuiApplication::overrideCursor() : QCursor();
    const auto cursorPixmap = currentCursor.pixmap();

    if (!cursorPixmap.isNull()) { return cursorPixmap.size(); }

    return QSize(16, 16);

}

QPoint
VirtualDesktopBar::getRelativeScreenPosition() const {
    const auto globalPos = QCursor::pos();
    auto currentScreen = QGuiApplication::screenAt(globalPos);

    if (!currentScreen) {
        currentScreen = QGuiApplication::primaryScreen();
    }

    if (currentScreen) {
        const auto screenGeometry = currentScreen->geometry();
        return screenGeometry.topLeft();
    }

    return {0, 0};
}

void
VirtualDesktopBar::onDesktopCreated(const QString &id, const KWin::KWinDesktopData &desktopData) {
    QVariantMap data;
    data[QSL("id")] = desktopData.id;
    data[QSL("uuid")] = desktopData.uuid;
    data[QSL("name")] = desktopData.name;

    Q_EMIT desktopCreated(id, data);
}

void
VirtualDesktopBar::onDesktopDataChanged(const QString &id, const KWin::KWinDesktopData &desktopData) {
    QVariantMap data;
    data[QSL("id")] = desktopData.id;
    data[QSL("uuid")] = desktopData.uuid;
    data[QSL("name")] = desktopData.name;

    Q_EMIT desktopDataChanged(id, data);
}

void
VirtualDesktopBar::onDesktopRemoved(const QString &id) {
    Q_EMIT desktopRemoved(id);
}

void
VirtualDesktopBar::onCurrentChanged(const QString &id) {
    Q_EMIT currentChanged(id);
}

#include "moc_VirtualDesktopBar.cpp"
