// plugin/VirtualDesktopBar.hpp
#pragma once

#include <QObject>
#include <QVariantList>
#include <QDBusInterface>
#include <QCursor>
#include <QGuiApplication>
#include <QPoint>

#include "KWinDesktop.h"

namespace DBus {
    namespace Services {
        inline auto KWin(QStringLiteral("org.kde.KWin"));
    }

    namespace Paths {
        inline auto KWin(QStringLiteral("/KWin"));
        inline auto VDManager(QStringLiteral("/VirtualDesktopManager"));
    }

    namespace Interfaces {
        inline auto KWin(QStringLiteral("org.kde.KWin"));
        inline auto VDManager(QStringLiteral("org.kde.KWin.VirtualDesktopManager"));
    }
}

class VirtualDesktopBar : public QObject {
    Q_OBJECT

public:
    explicit VirtualDesktopBar(QObject *parent = nullptr);
    ~VirtualDesktopBar() override;

    Q_INVOKABLE QVariantList requestDesktopInfoList();
    Q_INVOKABLE bool createDesktop(quint32 index, const QString &name);
    Q_INVOKABLE bool removeDesktop(QString id);
    Q_INVOKABLE bool setDesktopName(QString id, QString name);
    Q_INVOKABLE bool setCurrentDesktop(qint32 number);
    Q_INVOKABLE bool nextDesktop();
    Q_INVOKABLE bool previousDesktop();
    Q_INVOKABLE bool moveDesktop(const QString &id, quint32 targetIndex);
    Q_INVOKABLE QString getIconFromDesktopFile(const QString &desktopFile);
    Q_INVOKABLE QString getCurrentActivityId();
    Q_INVOKABLE QString getActivityName(const QString activityId);
    Q_INVOKABLE QPoint getCursorPosition() const;
    Q_INVOKABLE QPoint getRelativeCursorPosition() const;
    Q_INVOKABLE QPoint getRelativeScreenPosition() const;
    Q_INVOKABLE QSize getCursorSize() const;
    Q_INVOKABLE bool isMouseButtonPressed() const;
    Q_INVOKABLE void run(const QString &cmd) const;

Q_SIGNALS:
    void desktopCreated(const QString &id, const QVariantMap &desktopData);
    void desktopDataChanged(const QString &id, const QVariantMap &desktopData);
    void desktopRemoved(const QString &id);
    void currentChanged(const QString &id);

private Q_SLOTS:
    void onDesktopCreated(const QString &id, const KWin::KWinDesktopData &desktopData);
    void onDesktopDataChanged(const QString &id, const KWin::KWinDesktopData &desktopData);
    void onDesktopRemoved(const QString &id);
    void onCurrentChanged(const QString &id);

private:
    void connectToDBusSignals();
    QDBusInterface *createInterface(const QString& service, const QString& path, const QString& interface,
        const QDBusConnection &busType = QDBusConnection::sessionBus());
};