// plugin/VirtualDesktopBar.hpp
#pragma once

#include <QObject>
#include <QVariantList>
#include <QDBusInterface>
#include <QCursor>
#include <QGuiApplication>
#include <QPoint>
#include <QHash>
#include <QPointer>

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

class SignalTraceProbe : public QObject {
    Q_OBJECT

public:
    explicit SignalTraceProbe(QObject *target, QString label, QObject *parent = nullptr);
    [[nodiscard]] QObject *target() const;

public Q_SLOTS:
    void onAnySignal();

private:
    QPointer<QObject> m_target;
    QString m_label;
};

class VirtualDesktopBar : public QObject {
    Q_OBJECT

public:
    explicit VirtualDesktopBar(QObject *parent = nullptr);
    ~VirtualDesktopBar() override;

    Q_INVOKABLE static QVariantList requestDesktopInfoList();
    Q_INVOKABLE static QVariantList requestActivityInfoList();
    Q_INVOKABLE static bool createDesktop(quint32 index, const QString &name);
    Q_INVOKABLE static bool removeDesktop(const QString &id);
    Q_INVOKABLE static bool setDesktopName(const QString& id, const QString &name);
    Q_INVOKABLE static bool setCurrentDesktop(qint32 number);
    Q_INVOKABLE static bool nextDesktop();
    Q_INVOKABLE static bool previousDesktop();
    Q_INVOKABLE static bool moveDesktop(const QString &id, quint32 targetIndex);
    Q_INVOKABLE static QString getIconFromDesktopFile(const QString &desktopFile);
    Q_INVOKABLE static QString getCurrentActivityId();
    Q_INVOKABLE static QString getActivityName(const QString &activityId);
    Q_INVOKABLE static QPoint getCursorPosition() ;
    Q_INVOKABLE static QPoint getRelativeCursorPosition() ;
    Q_INVOKABLE static QPoint getRelativeScreenPosition() ;
    Q_INVOKABLE static QSize getCursorSize() ;
    Q_INVOKABLE static bool isMouseButtonPressed() ;
    Q_INVOKABLE static void run(const QString &cmd);
    Q_INVOKABLE void startSignalTrace(QObject *target, const QString &label = QString());
    Q_INVOKABLE void stopSignalTrace(QObject *target);
    Q_INVOKABLE void stopAllSignalTraces();

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
    static std::unique_ptr<QDBusInterface> createInterface(const QString& service, const QString& path, const QString& interface,
        const QDBusConnection &busType = QDBusConnection::sessionBus());
    QHash<QObject*, class SignalTraceProbe*> m_signalTraceProbes;
};
