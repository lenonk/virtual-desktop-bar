#pragma once

#include <QAction>
#include <QDBusInterface>
#include <QList>
#include <QObject>
#include <QString>
#include <QVariantList>

#include <netwm.h>

#include <KActionCollection>
#include <KWindowSystem>
#include <KWindowInfo>
#include <KX11Extras>
#include <KWayland/Client/plasmavirtualdesktop.h>
#include <KWayland/Client/plasmawindowmanagement.h>
#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/registry.h>

#include <virtualdesktopinfo.h>
#include "DesktopInfo.hpp"

struct WindowInfo {
    QList<KWindowInfo> x11WindowInfo;
    QList<KWayland::Client::PlasmaWindow *> waylandWindowInfo;
};

class VirtualDesktopBar : public QObject {
    Q_OBJECT

public:
    VirtualDesktopBar(QObject* parent = nullptr);
    ~VirtualDesktopBar();

    Q_INVOKABLE void requestDesktopInfoList();

    Q_INVOKABLE void showDesktop(QVariant d);
    Q_INVOKABLE void addDesktop(unsigned position = 0);
    Q_INVOKABLE void removeDesktop(int number);
    Q_INVOKABLE void renameDesktop(int number, QString name);
    Q_INVOKABLE void replaceDesktops(int number1, int number2);

    Q_PROPERTY(QString cfg_EmptyDesktopsRenameAs
               MEMBER cfg_EmptyDesktopsRenameAs
               NOTIFY cfg_EmptyDesktopsRenameAsChanged);

    Q_PROPERTY(QString cfg_AddingDesktopsExecuteCommand
               MEMBER cfg_AddingDesktopsExecuteCommand);

    Q_PROPERTY(bool cfg_DynamicDesktopsEnable
               MEMBER cfg_DynamicDesktopsEnable
               NOTIFY cfg_DynamicDesktopsEnableChanged);

    Q_PROPERTY(bool cfg_MultipleScreensFilterOccupiedDesktops
               MEMBER cfg_MultipleScreensFilterOccupiedDesktops
               NOTIFY cfg_MultipleScreensFilterOccupiedDesktopsChanged);

signals:
    void desktopInfoListSent(QVariantList desktopInfoList);
    void requestRenameCurrentDesktop();

    void cfg_EmptyDesktopsRenameAsChanged();
    void cfg_AddingDesktopsExecuteCommandChanged();
    void cfg_DynamicDesktopsEnableChanged();
    void cfg_MultipleScreensFilterOccupiedDesktopsChanged();

private:
    NETRootInfo *netRootInfo = nullptr;

    static TaskManager::VirtualDesktopInfo *vdi;
    // Wayland specific variables
    KWayland::Client::ConnectionThread *waylandConn = nullptr;
    KWayland::Client::Registry *waylandReg = nullptr;
    KWayland::Client::PlasmaVirtualDesktopManagement *waylandPvdm = nullptr;
    KWayland::Client::PlasmaWindowManagement *waylandPwm = nullptr;
    QThread *connThread = nullptr;
    qint32 pvdName = 0, pvdVersion = 0;
    qint32 pwmName = 0, pwmVersion = 0;

    QDBusInterface dbusInterface;
    QString dbusInterfaceName;

    void setupSignals();
    void setupKWinSignals();
    void setupInternalSignals();
    void setupGlobalKeyboardShortcuts();

    DesktopInfo getDesktopInfo(int number);
    DesktopInfo getDesktopInfo(QString id);
    QList<DesktopInfo> getDesktopInfoList(bool extraInfo = false);
    QList<int> getEmptyDesktopNumberList(bool noCheating = true);
    WindowInfo getWindowInfoList(QString desktopId, bool ignoreScreens = false);
    QList<KWindowInfo> getX11Windows(QString desktopId, bool ignoreScreens);
    QList<KWayland::Client::PlasmaWindow *> getWaylandWindows(QString desktopId, bool ignoreScreens);
    bool windowIntersectsScreen(QRect winRect);
    void setCurrentDesktop(qint32 number);

    QString cfg_EmptyDesktopsRenameAs;
    QString cfg_AddingDesktopsExecuteCommand;
    bool cfg_DynamicDesktopsEnable;
    bool cfg_MultipleScreensFilterOccupiedDesktops;
    bool cfg_MultipleScreensEnableSeparateDesktops;

    void sendDesktopInfoList();
    bool sendDesktopInfoListLock;

    void tryAddEmptyDesktop();
    bool tryAddEmptyDesktopLock;

    void tryRemoveEmptyDesktops();
    bool tryRemoveEmptyDesktopsLock;

    void tryRenameEmptyDesktops();
    bool tryRenameEmptyDesktopsLock;

    void processChanges(std::function<void()> callback, bool& lock);
    void initWaylandConnection();
    void initWaylandRegistry();

    QVariant currentDesktop;
    QVariant mostRecentDesktop;
    void updateLocalDesktopNumbers();

    KActionCollection* actionCollection;
    QAction* actionSwitchToRecentDesktop;
    QAction* actionAddDesktop;
    QAction* actionRemoveLastDesktop;
    QAction* actionRemoveCurrentDesktop;
    QAction* actionRenameCurrentDesktop;
    QAction* actionMoveCurrentDesktopToLeft;
    QAction* actionMoveCurrentDesktopToRight;
};


