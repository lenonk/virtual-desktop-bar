#include "VirtualDesktopBar.hpp"

#include <functional>
#include <thread>
#include <chrono>

#include <QGuiApplication>
#include <QRegularExpression>
#include <QScreen>
#include <QTimer>
#include <QThread>

#include <KGlobalAccel>
#include <KX11Extras>

TaskManager::VirtualDesktopInfo *VirtualDesktopBar::vdi = nullptr;

using namespace KWayland::Client;

VirtualDesktopBar::VirtualDesktopBar(QObject* parent) : QObject(parent),
        dbusInterface("org.kde.KWin", "/VirtualDesktopManager"),
        dbusInterfaceName("org.kde.KWin.VirtualDesktopManager"),
        sendDesktopInfoListLock(false),
        tryAddEmptyDesktopLock(false),
        tryRemoveEmptyDesktopsLock(false),
        tryRenameEmptyDesktopsLock(false) {

    if (KWindowSystem::isPlatformWayland()) {
        initWaylandConnection();
    }

    vdi = new TaskManager::VirtualDesktopInfo();
    currentDesktop = vdi->currentDesktop();
    mostRecentDesktop = currentDesktop;

    setupSignals();
    setupGlobalKeyboardShortcuts();
}

VirtualDesktopBar::~VirtualDesktopBar() noexcept
{
    if (vdi) {
        delete vdi;
        vdi = nullptr;
    }
    if (waylandConn) {
        waylandConn->deleteLater();
        connThread->quit();
        connThread->wait();
    }
}

#include <iostream>
void VirtualDesktopBar::initWaylandRegistry() {
    waylandReg = new Registry();
    waylandReg->create(waylandConn);

    connect(waylandReg, &Registry::plasmaVirtualDesktopManagementAnnounced,
            [this](qint32 n, qint32 v) {
                pvdName = n;
                pvdVersion = v;
            });

    connect(waylandReg, &Registry::plasmaVirtualDesktopManagementRemoved,
            [this](qint32 n) {
                if (n != pvdName)
                    return;
                pvdName = 0;
                pvdVersion = 0;
            });

    connect(waylandReg, &Registry::plasmaWindowManagementAnnounced,
            [this](qint32 n, qint32 v) {
                pwmName = n;
                pwmVersion = v;
            });

    connect(waylandReg, &Registry::plasmaWindowManagementRemoved,
            [this](qint32 n) {
                if (n != pwmName)
                    return;
                pwmName = 0;
                pwmVersion = 0;
            });

    connect(waylandConn, &ConnectionThread::connectionDied, waylandReg, &Registry::destroy);
    waylandReg->setup();
    waylandConn->roundtrip();

    // Wait for Announcements
    while (pvdName == 0 && pvdVersion == 0 && pwmName == 0 && pwmVersion == 0) {
        // TODO: Add some sort of timeout here so this isn't a potential infinite loop'
        std::this_thread::yield();
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void VirtualDesktopBar::initWaylandConnection() {
    // Set up Wayland socket connection
    waylandConn = new ConnectionThread();
    connThread = new QThread();
    waylandConn->moveToThread(connThread);
    connThread->start();

    std::atomic_bool isReady { false };
    std::atomic_bool failed { false };
    connect(waylandConn, &ConnectionThread::connected, [&isReady] {
        isReady = true;
    });

    connect(waylandConn, &ConnectionThread::failed, [&isReady, &failed] {
        failed = isReady = true;
    });

    waylandConn->initConnection();

    while (!isReady) {
        std::this_thread::yield();
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    if (!failed) {
        initWaylandRegistry();

        // Set up PlasmaVirtualDesktopManagement
        waylandPvdm = waylandReg->createPlasmaVirtualDesktopManagement(pvdName, pvdVersion);
        if (!waylandPvdm->isValid()) {
            // TODO: Delete all the wayland stuff and do some sort of message saying
            // Wayland virtual desktop management won't be available'
        }
        connect(waylandConn, &ConnectionThread::connectionDied, waylandPvdm, &PlasmaVirtualDesktopManagement::destroy);

        // Set up PlasmaWindowManagement
        waylandPwm = waylandReg->createPlasmaWindowManagement(pwmName, pwmVersion);
        if (!waylandPwm->isValid()) {
            // TODO: Delete all the wayland stuff and do some sort of message saying
            // Wayland window management won't be available'
        }
    }

    connect(waylandConn, &ConnectionThread::connectionDied, waylandPwm, &PlasmaWindowManagement::destroy);
}

void VirtualDesktopBar::requestDesktopInfoList() {
    sendDesktopInfoList();
}

void VirtualDesktopBar::showDesktop(QVariant d) {
    vdi->requestActivate(d);
}

void VirtualDesktopBar::addDesktop(unsigned /*position*/) {
    vdi->requestCreateDesktop(vdi->numberOfDesktops());

    if (!cfg_AddingDesktopsExecuteCommand.isEmpty()) {
        QTimer::singleShot(100, [=] {
            QString command = "(" + cfg_AddingDesktopsExecuteCommand + ") &";
            system(command.toStdString().c_str());
        });
    }
}

#include <iostream>
void VirtualDesktopBar::removeDesktop(int number) {
    if (vdi->numberOfDesktops() == 1) { return; };

    if (KWindowSystem::isPlatformWayland())
        vdi->requestRemoveDesktop(number);
    else if (KWindowSystem::isPlatformX11()) {
        dbusInterface.call("removeDesktop", getDesktopInfo(number).id);
    }
}

void VirtualDesktopBar::renameDesktop(int number, QString name) {
    auto reply = dbusInterface.call("setDesktopName", getDesktopInfo(number).id, name);

    if (KWindowSystem::isPlatformWayland() && reply.type() == QDBusMessage::ErrorMessage) {
        // TODO: Something for wayland??  I don't see a way to rename an
        // existing wayland virtual desktop, though it must exist because you can do it
        // from settings.  A workaround may be to delete and recreate the desktop with
        // a new name and move all the windows to the new desktop.  Let's see how often
        // the dbus call fails though.
    }
    else if (reply.type() == QDBusMessage::ErrorMessage) {
        KX11Extras::setDesktopName(number, name);
    }
}

void VirtualDesktopBar::replaceDesktops(int number1, int number2) {
    if (number1 == number2) {
        return;
    }
    if (number1 < 1 || number1 > vdi->numberOfDesktops()) {
        return;
    }
    if (number2 < 1 || number2 > vdi->numberOfDesktops()) {
        return;
    }

    auto desktopInfo1 = getDesktopInfo(number1);
    auto desktopInfo2 = getDesktopInfo(number2);

    auto windowInfoList1 = getWindowInfoList(desktopInfo1.id);
    auto windowInfoList2 = getWindowInfoList(desktopInfo2.id);


    if (desktopInfo1.isCurrent)
        vdi->requestActivate(desktopInfo2.id);
    else if (desktopInfo2.isCurrent)
        vdi->requestActivate(desktopInfo1.id);

    if (KWindowSystem::isPlatformWayland()) {
        for (auto& winInfo : windowInfoList2.waylandWindowInfo) {
            winInfo->requestEnterVirtualDesktop(desktopInfo1.id);
            winInfo->requestLeaveVirtualDesktop(desktopInfo2.id);
        }

        for (auto& winInfo : windowInfoList1.waylandWindowInfo) {
            winInfo->requestEnterVirtualDesktop(desktopInfo2.id);
            winInfo->requestLeaveVirtualDesktop(desktopInfo1.id);
        }
    }
    else if (KWindowSystem::isPlatformX11()) {
        for (auto& winInfo : windowInfoList2.x11WindowInfo) {
            KX11Extras::setOnDesktop(winInfo.win(), desktopInfo1.number);
        }

        for (auto& winInfo : windowInfoList1.x11WindowInfo) {
            KX11Extras::setOnDesktop(winInfo.win(), desktopInfo2.number);
        }
    }

    renameDesktop(desktopInfo1.number, desktopInfo2.name);
    renameDesktop(desktopInfo2.number, desktopInfo1.name);
}

void VirtualDesktopBar::setupSignals() {
    setupKWinSignals();
    setupInternalSignals();
}

void VirtualDesktopBar::setupKWinSignals() {
    QObject::connect(vdi, &TaskManager::VirtualDesktopInfo::currentDesktopChanged, this, [&] {
        updateLocalDesktopNumbers();
        processChanges([&] { sendDesktopInfoList(); }, sendDesktopInfoListLock);
    });

    QObject::connect(vdi, &TaskManager::VirtualDesktopInfo::numberOfDesktopsChanged, this, [&] {
        processChanges([&] { tryAddEmptyDesktop(); }, tryAddEmptyDesktopLock);
        processChanges([&] { tryRemoveEmptyDesktops(); }, tryRemoveEmptyDesktopsLock);
        processChanges([&] { tryRenameEmptyDesktops(); }, tryRenameEmptyDesktopsLock);
        processChanges([&] { sendDesktopInfoList(); }, sendDesktopInfoListLock);
    });

    QObject::connect(vdi, &TaskManager::VirtualDesktopInfo::desktopNamesChanged, this, [&] {
        processChanges([&] { sendDesktopInfoList(); }, sendDesktopInfoListLock);
    });

    if (KWindowSystem::isPlatformX11()) {
        // NOTE: Not sure what this is for...
        QObject::connect(KX11Extras::self(), static_cast<void (KX11Extras::*)(WId, NET::Properties, NET::Properties2)>
                                                (&KX11Extras::windowChanged), this, [&](WId, NET::Properties properties, NET::Properties2) {
            if (properties & NET::WMState) {
                processChanges([&] { tryAddEmptyDesktop(); }, tryAddEmptyDesktopLock);
                processChanges([&] { tryRemoveEmptyDesktops(); }, tryRemoveEmptyDesktopsLock);
                processChanges([&] { tryRenameEmptyDesktops(); }, tryRenameEmptyDesktopsLock);
                processChanges([&] { sendDesktopInfoList(); }, sendDesktopInfoListLock);
            }
        });
    }
}

void VirtualDesktopBar::setupInternalSignals() {
    QObject::connect(this, &VirtualDesktopBar::cfg_EmptyDesktopsRenameAsChanged, this, [&] {
        tryRenameEmptyDesktops();
    });

    QObject::connect(this, &VirtualDesktopBar::cfg_DynamicDesktopsEnableChanged, this, [&] {
        tryAddEmptyDesktop();
        tryRemoveEmptyDesktops();
    });

    QObject::connect(this, &VirtualDesktopBar::cfg_MultipleScreensFilterOccupiedDesktopsChanged, this, [&] {
        sendDesktopInfoList();
    });
}

void VirtualDesktopBar::setupGlobalKeyboardShortcuts() {
    QString prefix = "Virtual Desktop Bar - ";
    actionCollection = new KActionCollection(this, QStringLiteral("kwin"));

    actionSwitchToRecentDesktop = actionCollection->addAction(QStringLiteral("switchToRecentDesktop"));
    actionSwitchToRecentDesktop->setText(prefix + "Switch to Recent Desktop");
    QObject::connect(actionSwitchToRecentDesktop, &QAction::triggered, this, [&] {
        showDesktop(mostRecentDesktop);
    });
    KGlobalAccel::setGlobalShortcut(actionSwitchToRecentDesktop, QKeySequence());

    actionAddDesktop = actionCollection->addAction(QStringLiteral("addDesktop"));
    actionAddDesktop->setText(prefix + "Add Desktop");
    QObject::connect(actionAddDesktop, &QAction::triggered, this, [&] {
        if (!cfg_DynamicDesktopsEnable) {
            addDesktop();
        }
    });
    KGlobalAccel::setGlobalShortcut(actionAddDesktop, QKeySequence());

    actionRemoveLastDesktop = actionCollection->addAction(QStringLiteral("removeLastDesktop"));
    actionRemoveLastDesktop->setText(prefix + "Remove Last Desktop");
    QObject::connect(actionRemoveLastDesktop, &QAction::triggered, this, [&] {
        if (!cfg_DynamicDesktopsEnable) {
            removeDesktop(KWindowSystem::isPlatformWayland() ? vdi->numberOfDesktops() - 1 : vdi->numberOfDesktops());
        }
    });
    KGlobalAccel::setGlobalShortcut(actionRemoveLastDesktop, QKeySequence());

    actionRemoveCurrentDesktop = actionCollection->addAction(QStringLiteral("removeCurrentDesktop"));
    actionRemoveCurrentDesktop->setText(prefix + "Remove Current Desktop");
    QObject::connect(actionRemoveCurrentDesktop, &QAction::triggered, this, [&] {
        if (!cfg_DynamicDesktopsEnable) {
            removeDesktop(vdi->position(vdi->currentDesktop()));
        }
    });
    KGlobalAccel::setGlobalShortcut(actionRemoveCurrentDesktop, QKeySequence());

    actionRenameCurrentDesktop = actionCollection->addAction(QStringLiteral("renameCurrentDesktop"));
    actionRenameCurrentDesktop->setText(prefix + "Rename Current Desktop");
    QObject::connect(actionRenameCurrentDesktop, &QAction::triggered, this, [&] {
        emit requestRenameCurrentDesktop();
    });
    KGlobalAccel::setGlobalShortcut(actionRenameCurrentDesktop, QKeySequence());

    actionMoveCurrentDesktopToLeft = actionCollection->addAction(QStringLiteral("moveCurrentDesktopToLeft"));
    actionMoveCurrentDesktopToLeft->setText(prefix + "Move Current Desktop to Left");
    QObject::connect(actionMoveCurrentDesktopToLeft, &QAction::triggered, this, [&] {
        replaceDesktops(KX11Extras::currentDesktop(),
                        KX11Extras::currentDesktop() - 1);
    });
    KGlobalAccel::setGlobalShortcut(actionMoveCurrentDesktopToLeft, QKeySequence());

    actionMoveCurrentDesktopToRight = actionCollection->addAction(QStringLiteral("moveCurrentDesktopToRight"));
    actionMoveCurrentDesktopToRight->setText(prefix + "Move Current Desktop to Right");
    QObject::connect(actionMoveCurrentDesktopToRight, &QAction::triggered, this, [&] {
        replaceDesktops(KX11Extras::currentDesktop(),
                        KX11Extras::currentDesktop() + 1);
    });
    KGlobalAccel::setGlobalShortcut(actionMoveCurrentDesktopToRight, QKeySequence());
}

void VirtualDesktopBar::processChanges(std::function<void()> callback, bool& lock) {
    if (!lock) {
        lock = true;
        QTimer::singleShot(1, [callback, &lock] {
            lock = false;
            callback();
        });
    }
}

DesktopInfo VirtualDesktopBar::getDesktopInfo(int number) {
    for (auto& desktopInfo : getDesktopInfoList()) {
        if ((KWindowSystem::isPlatformWayland() && desktopInfo.number == number) ||
            (KWindowSystem::isPlatformX11() && desktopInfo.number == number + 1)) {
            return desktopInfo;
        }
    }
    return DesktopInfo();
}

DesktopInfo VirtualDesktopBar::getDesktopInfo(QString id) {
    for (auto& desktopInfo : getDesktopInfoList()) {
        if (desktopInfo.id == id) {
            return desktopInfo;
        }
    }
    return DesktopInfo();
}

QList<DesktopInfo> VirtualDesktopBar::getDesktopInfoList(bool extraInfo) {
    QList<DesktopInfo> desktopInfoList;

    auto desktopIDs = vdi->desktopIds();
    auto desktopNames = vdi->desktopNames();
    for (int i = 0; i < desktopIDs.length(); i++) {
        DesktopInfo di;
        di.id = desktopIDs[i].toString();
        di.name = desktopNames[i];
        di.number = KWindowSystem::isPlatformX11() ? i + 1 : i;

        desktopInfoList << di;
    }

    for (auto& desktopInfo : desktopInfoList) {
        desktopInfo.isCurrent = desktopInfo.id == vdi->currentDesktop().toString();

        if (!extraInfo) {
            continue;
        }

        auto wInfo = getWindowInfoList(desktopInfo.id);

        if (KWindowSystem::isPlatformWayland()) {
            desktopInfo.isEmpty = wInfo.waylandWindowInfo.isEmpty();
            for (int i = 0; i < wInfo.waylandWindowInfo.length(); i++) {
                auto& windowInfo = wInfo.waylandWindowInfo[i];

                if (!desktopInfo.isUrgent)
                    desktopInfo.isUrgent = windowInfo->isDemandingAttention();

                QString windowName = windowInfo->title();
                int separatorPosition = qMax(windowName.lastIndexOf(" - "),
                                            qMax(windowName.lastIndexOf(" – "),
                                                windowName.lastIndexOf(" — ")));
                if (separatorPosition >= 0) {
                    separatorPosition += 3;
                    int length = windowName.length() - separatorPosition;
                    windowName = windowName.mid(separatorPosition, windowName.length() - separatorPosition).trimmed();
                }

                if (i == 0) {
                    desktopInfo.activeWindowName = windowName;
                }

                desktopInfo.windowNameList << windowName;
            }
        }
        else if (KWindowSystem::isPlatformX11()) {
            desktopInfo.isEmpty = wInfo.x11WindowInfo.isEmpty();
            for (int i = 0; i < wInfo.x11WindowInfo.length(); i++) {
                auto& windowInfo = wInfo.x11WindowInfo[i];

                if (!desktopInfo.isUrgent)
                    desktopInfo.isUrgent = windowInfo.hasState(NET::DemandsAttention);

                QString windowName = windowInfo.name();
                int separatorPosition = qMax(windowName.lastIndexOf(" - "),
                                            qMax(windowName.lastIndexOf(" – "),
                                                windowName.lastIndexOf(" — ")));
                if (separatorPosition >= 0) {
                    separatorPosition += 3;
                    int length = windowName.length() - separatorPosition;
                    windowName = windowName.mid(separatorPosition, windowName.length() - separatorPosition).trimmed();
                }

                if (i == 0) {
                    desktopInfo.activeWindowName = windowName;
                }

                desktopInfo.windowNameList << windowName;
            }
        }
    }

    return desktopInfoList;
}

bool
VirtualDesktopBar::windowIntersectsScreen(QRect winRect) {
    auto screenRect = QGuiApplication::screens().at(0)->geometry();
    auto intersectionRect = screenRect.intersected(winRect);
    if (intersectionRect.width() < winRect.width() / 2 ||
        intersectionRect.height() < winRect.height() / 2) {
        return false;
    }

    return true;
}

QList<KWindowInfo>
VirtualDesktopBar::getX11Windows(QString desktopId, bool ignoreScreens) {
    QList<KWindowInfo> winInfo;

    QList<WId> windowIds = KX11Extras::stackingOrder();
    for (int i = windowIds.length() - 1; i >= 0; i--) {
        KWindowInfo windowInfo(windowIds[i], NET::WMState |
                                             NET::WMDesktop |
                                             NET::WMGeometry |
                                             NET::WMWindowType |
                                             NET::WMName);

        // Skipping windows not present on the current desktops
        if (!windowInfo.isOnDesktop(desktopId.toInt())) {
            continue;
        }

        // Skipping some flagged windows
        if (windowInfo.hasState(NET::SkipPager) ||
            windowInfo.hasState(NET::SkipTaskbar)) {
            continue;
        }

        auto windowType = windowInfo.windowType(NET::AllTypesMask);
        if (windowType != -1 &&
            ((windowType == NET::Dock) ||
             (windowType == NET::Desktop))) {
            continue;
        }

        // Skipping windows not present on the current screen
        if (!ignoreScreens && cfg_MultipleScreensFilterOccupiedDesktops) {
            if (!windowIntersectsScreen(windowInfo.geometry()))
                continue;
        }

        winInfo << windowInfo;
    }

    return winInfo;
}

QList<PlasmaWindow *>
VirtualDesktopBar::getWaylandWindows(QString desktopId, bool ignoreScreens) {
    QList<PlasmaWindow *> winInfo;

    for (auto &win : waylandPwm->windows()) {
        // Skip windows with no title.  Not sure why this happens, but several windows
        // with no title are on all desktops
        if (win->title().isEmpty())
            continue;

        // Skip windows flagged SkipSwitcher or SkipTaskbar
        if (win->skipSwitcher() || win->skipTaskbar()) {
            continue;
        }

        // Skip windows not present on the current desktops
        if (!win->isOnAllDesktops() &&
            !win->plasmaVirtualDesktops().contains(desktopId)) {
            continue;
        }

        // Skipping windows not present on the current screen
        if (!ignoreScreens && cfg_MultipleScreensFilterOccupiedDesktops) {
            if (!windowIntersectsScreen(win->geometry()))
                continue;
        }

        winInfo << win;
    }

    return winInfo;
}

WindowInfo
VirtualDesktopBar::getWindowInfoList(QString desktopId, bool ignoreScreens) {
    WindowInfo winInfo;
    if (KWindowSystem::isPlatformWayland())
        winInfo.waylandWindowInfo = getWaylandWindows(desktopId, ignoreScreens);
    if (KWindowSystem::isPlatformX11())
        winInfo.x11WindowInfo = getX11Windows(desktopId, ignoreScreens);

    return winInfo;
}

QList<int> VirtualDesktopBar::getEmptyDesktopNumberList(bool noCheating) {
    QList<int> emptyDesktopNumberList;

    for (int i = 0; i < vdi->numberOfDesktops(); i++) {
        auto desktopInfo = getDesktopInfo(i);
        auto wInfo = getWindowInfoList(desktopInfo.id, true);

        if (noCheating) {
            if (KWindowSystem::isPlatformWayland()) {
                if (wInfo.waylandWindowInfo.empty())
                    emptyDesktopNumberList << i;
            }
            else if (KWindowSystem::isPlatformX11()) {
                if (wInfo.x11WindowInfo.empty())
                    emptyDesktopNumberList << i;
            }
            continue;
        }

        bool isConsideredEmpty = true;
        if (KWindowSystem::isPlatformWayland()) {
            for (auto& windowInfo : wInfo.waylandWindowInfo) {
                if (windowInfo->plasmaVirtualDesktops().contains(desktopInfo.id)) {
                   isConsideredEmpty = false;
                   break;
                }
            }
            if (isConsideredEmpty) {
                emptyDesktopNumberList << i;
            }
        }
        else if (KWindowSystem::isPlatformX11()) {
            for (auto& windowInfo : wInfo.x11WindowInfo) {
                if (windowInfo.desktop() == i + 1) {
                    isConsideredEmpty = false;
                    break;
                }
            }

            if (isConsideredEmpty) {
                emptyDesktopNumberList << i;
            }
        }
    }

    return emptyDesktopNumberList;
}

void VirtualDesktopBar::sendDesktopInfoList() {
    QVariantList desktopInfoList;
    for (auto& desktopInfo : getDesktopInfoList(true)) {
        desktopInfoList << desktopInfo.toQVariantMap();
    }
    emit desktopInfoListSent(desktopInfoList);
}

void VirtualDesktopBar::tryAddEmptyDesktop() {
    if (cfg_DynamicDesktopsEnable) {
        auto emptyDesktopNumberList = getEmptyDesktopNumberList(false);
        if (emptyDesktopNumberList.empty()) {
            addDesktop();
        }
    }
}

void VirtualDesktopBar::tryRemoveEmptyDesktops() {
    if (cfg_DynamicDesktopsEnable) {
        auto emptyDesktopNumberList = getEmptyDesktopNumberList(false);
        for (int i = 0; i < emptyDesktopNumberList.length(); i++) {
            int desktopNumber = emptyDesktopNumberList[i];
            if (KWindowSystem::isPlatformWayland())
                removeDesktop(desktopNumber);
            else if (KWindowSystem::isPlatformX11())
                removeDesktop(desktopNumber + 1);
        }
    }
}

void VirtualDesktopBar::tryRenameEmptyDesktops() {
    if (!cfg_EmptyDesktopsRenameAs.isEmpty()) {
        auto emptyDesktopNumberList = getEmptyDesktopNumberList();
        for (int desktopNumber : emptyDesktopNumberList) {
            if (KWindowSystem::isPlatformWayland())
                renameDesktop(desktopNumber, cfg_EmptyDesktopsRenameAs);
            else if (KWindowSystem::isPlatformX11())
                renameDesktop(desktopNumber + 1, cfg_EmptyDesktopsRenameAs);
        }
    }
}

void VirtualDesktopBar::updateLocalDesktopNumbers() {
    QVariant d = vdi->currentDesktop();
    if (currentDesktop != d) {
        mostRecentDesktop = currentDesktop;
    }
    currentDesktop = d;
}
