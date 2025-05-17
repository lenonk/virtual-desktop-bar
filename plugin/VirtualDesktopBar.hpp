// plugin/VirtualDesktopBar.hpp
#pragma once

#include <map>

#include <QObject>
#include <QDBusInterface>
#include <QVariantList>
#include <QDBusArgument>

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

struct KWinDesktop {
    qint32 id    {};
    QString uuid {};
    QString name {};
};
Q_DECLARE_METATYPE(KWinDesktop)
Q_DECLARE_METATYPE(QList<KWinDesktop>)

class VirtualDesktopBar : public QObject {
    Q_OBJECT

public:
    explicit VirtualDesktopBar(QObject *parent = nullptr);
    ~VirtualDesktopBar() override;

    Q_INVOKABLE QVariantList requestDesktopInfoList();

Q_SIGNALS:
    // void desktopInfoListSent(const QVariantList& desktopInfoList);

private:
    QDBusInterface *createInterface(const QString& service, const QString& path, const QString& interface,
        const QDBusConnection &busType = QDBusConnection::sessionBus());

    std::map<QString, QDBusInterface *> m_interfaces;
};
