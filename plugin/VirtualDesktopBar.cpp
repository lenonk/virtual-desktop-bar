#include <ranges>

#include <QString>
#include <QDBusMetaType>
#include <QStandardPaths>
#include <QDir>
#include <QScreen>
#include <QDBusConnectionInterface>
#include <QProcess>
#include <QMetaMethod>

#include <KService>
#include <PlasmaActivities/Consumer>

#include "VirtualDesktopBar.hpp"

#define QSL(str) QStringLiteral(str)

SignalTraceProbe::SignalTraceProbe(QObject *target, QString label, QObject *parent)
    : QObject(parent), m_target(target), m_label(std::move(label)) {
}

QObject *SignalTraceProbe::target() const {
    return m_target.data();
}

void SignalTraceProbe::onAnySignal() {
    QObject *signalSender = sender();
    if (!signalSender) {
        return;
    }

    const int signalIndex = senderSignalIndex();
    QByteArray signalSignature("<unknown>");
    if (signalIndex >= 0 && signalIndex < signalSender->metaObject()->methodCount()) {
        signalSignature = signalSender->metaObject()->method(signalIndex).methodSignature();
    }

    const QString label = m_label.isEmpty() ? QString::fromLatin1(signalSender->metaObject()->className()) : m_label;
    qInfo().noquote().nospace()
        << "[virtualdesktopbar][signal] "
        << label
        << " sender=" << signalSender->metaObject()->className()
        << "@" << signalSender
        << " signal=" << signalSignature;
}

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

VirtualDesktopBar::~VirtualDesktopBar() = default;

void VirtualDesktopBar::startSignalTrace(QObject *target, const QString &label) {
    if (!target) {
        qWarning() << "startSignalTrace called with null target";
        return;
    }

    if (m_signalTraceProbes.contains(target)) {
        return;
    }

    auto *probe = new SignalTraceProbe(target, label, this);
    int hookedSignalCount = 0;
    const QMetaObject *metaObject = target->metaObject();
    const int methodCount = metaObject->methodCount();

    for (int methodIndex = 0; methodIndex < methodCount; ++methodIndex) {
        const QMetaMethod method = metaObject->method(methodIndex);
        if (method.methodType() != QMetaMethod::Signal) {
            continue;
        }

        const QByteArray encodedSignal = "2" + method.methodSignature();
        const bool connected = QObject::connect(target, encodedSignal.constData(), probe, SLOT(onAnySignal()));
        if (connected) {
            ++hookedSignalCount;
        }
    }

    if (hookedSignalCount == 0) {
        qWarning() << "No signals were connected for target" << target;
        probe->deleteLater();
        return;
    }

    m_signalTraceProbes.insert(target, probe);
    QObject::connect(target, &QObject::destroyed, this, [this, target]() {
        m_signalTraceProbes.remove(target);
    });

    qInfo() << "Signal tracing enabled for" << target << "with" << hookedSignalCount << "signals";
}

void VirtualDesktopBar::stopSignalTrace(QObject *target) {
    if (!target) {
        return;
    }

    auto it = m_signalTraceProbes.find(target);
    if (it == m_signalTraceProbes.end()) {
        return;
    }

    SignalTraceProbe *probe = it.value();
    QObject::disconnect(target, nullptr, probe, nullptr);
    m_signalTraceProbes.erase(it);
    probe->deleteLater();
}

void VirtualDesktopBar::stopAllSignalTraces() {
    for (auto it = m_signalTraceProbes.begin(); it != m_signalTraceProbes.end(); ++it) {
        QObject *target = it.key();
        SignalTraceProbe *probe = it.value();
        if (target) {
            QObject::disconnect(target, nullptr, probe, nullptr);
        }
        probe->deleteLater();
    }
    m_signalTraceProbes.clear();
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

std::unique_ptr<QDBusInterface>
VirtualDesktopBar::createInterface(const QString &service, const QString &path, const QString &interface,
    const QDBusConnection &busType) {

    auto iface = std::make_unique<QDBusInterface>(service, path, interface, busType, nullptr);

    if (!iface->isValid()) {
        qWarning() << QSL("Failed to create interface %1 for %2:%3").arg(service, path, interface);
        return nullptr;
    }

    return iface;
}

QVariantList
VirtualDesktopBar::requestDesktopInfoList() {
    auto getDesktopsProperty = []() -> KWin::KWinDesktopDataList {
        QDBusMessage msg = QDBusMessage::createMethodCall( DBus::Services::KWin, DBus::Paths::VDManager,
           QSL("org.freedesktop.DBus.Properties"), QSL("Get"));

        msg << DBus::Interfaces::VDManager << QSL("desktops");

        const QDBusMessage reply = QDBusConnection::sessionBus().call(msg);
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
VirtualDesktopBar::createDesktop(const quint32 index, const QString &name) {
    QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::VDManager,
       DBus::Interfaces::VDManager, QSL("createDesktop"));

    msg << index << name;

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << QSL("Failed to create desktop: Name: %1, Index: %2").arg(name, static_cast<int32_t>(index));
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::removeDesktop(const QString &id) {
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
VirtualDesktopBar::setDesktopName(const QString& id, const QString &name) {
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
    const QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::KWin,
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
    const QDBusMessage msg = QDBusMessage::createMethodCall(DBus::Services::KWin, DBus::Paths::KWin,
       DBus::Interfaces::KWin, QSL("previousDesktop"));

    const auto reply = QDBusConnection::sessionBus().call(msg, QDBus::Block);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "Failed to call previousDesktop()";
        return false;
    }

    return true;
}

bool
VirtualDesktopBar::moveDesktop(const QString &id, const quint32 targetIndex) {
    // Get all desktops
    auto desktops = requestDesktopInfoList();
    if (desktops.isEmpty()) {
        qWarning() << "No desktops found";
        return false;
    }

    int currentIndex = -1;
    for (int i = 0; i < desktops.size(); ++i) {
        const auto desktop = desktops[i].toMap();
        if (desktop[QSL("uuid")].toString() == id) {
            currentIndex = i;
            break;
        }
    }

    if (currentIndex == -1) {
        qWarning() << "Desktop not found:" << id;
        return false;
    }

    if (currentIndex == static_cast<int>(targetIndex)) {
        return true; // Already at target position
    }

    // KWin doesn't support reordering desktops, so we swap names to simulate it
    // This is a workaround - windows stay on their desktop numbers, but the names move
    auto sourceDesktop = desktops[currentIndex].toMap();
    auto targetDesktop = desktops[targetIndex].toMap();

    const QString sourceName = sourceDesktop[QSL("name")].toString();
    const QString sourceUuid = sourceDesktop[QSL("uuid")].toString();
    const QString targetName = targetDesktop[QSL("name")].toString();
    const QString targetUuid = targetDesktop[QSL("uuid")].toString();

    // Swap the names
    if (!setDesktopName(sourceUuid, targetName)) {
        qWarning() << "Failed to set source desktop name";
        return false;
    }

    if (!setDesktopName(targetUuid, sourceName)) {
        qWarning() << "Failed to set target desktop name";
        // Try to rollback
        setDesktopName(sourceUuid, sourceName);
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

    if (KService::Ptr service = KService::serviceByDesktopName(serviceName)) {
        return service->icon();
    }

    return QSL("application-x-executable");
}

QString
VirtualDesktopBar::getCurrentActivityId() {
    const KActivities::Consumer consumer;
    return consumer.currentActivity();
}

QString
VirtualDesktopBar::getActivityName(const QString &activityId) {
    const KActivities::Info activityInfo(activityId);
    return activityInfo.name();
}

QVariantList
VirtualDesktopBar::requestActivityInfoList() {
    const KActivities::Consumer consumer;

    QVariantList out;
    const auto uuids = consumer.activities();

    out.reserve(uuids.size());
    for (const auto &uuid: uuids) {
        const KActivities::Info info(uuid);
        QVariantMap m;
        m[QSL("id")] = uuid;
        m[QSL("name")] = info.name();
        m[QSL("icon")] = info.icon();
        out.append(m);
    }

    return out;
}

QPoint
VirtualDesktopBar::getCursorPosition() {
    return QCursor::pos();
}

QPoint
VirtualDesktopBar::getRelativeCursorPosition() {
    const auto globalPos = QCursor::pos();
    auto currentScreen = QGuiApplication::screenAt(globalPos);

    if (!currentScreen) {
        currentScreen = QGuiApplication::primaryScreen();
    }

    if (currentScreen) {
        const auto screenGeometry = currentScreen->geometry();

        return {globalPos.x() - screenGeometry.x(), globalPos.y() - screenGeometry.y()};
    }

    return globalPos;
}
QSize
VirtualDesktopBar::getCursorSize() {
    const auto currentCursor = QGuiApplication::overrideCursor() ? *QGuiApplication::overrideCursor() : QCursor();
    const auto cursorPixmap = currentCursor.pixmap();

    if (!cursorPixmap.isNull()) { return cursorPixmap.size(); }

    return {16, 16};

}

bool
VirtualDesktopBar::isMouseButtonPressed() {
    return QGuiApplication::mouseButtons() & Qt::LeftButton;
}

void
VirtualDesktopBar::run(const QString &cmd) {
    qInfo() << "Running command:" << cmd;
    QProcess::startDetached(cmd);
}

QPoint
VirtualDesktopBar::getRelativeScreenPosition() {
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
