#pragma once

#include <QDBusArgument>
#include <QDBusVariant>
#include <QString>

namespace KWin {
    struct KWinDesktopData {
        int     id      {};
        QString uuid    {};
        QString name    {};
    };
    typedef QList<KWinDesktopData> KWinDesktopDataList;
}

Q_DECLARE_METATYPE(KWin::KWinDesktopData)
Q_DECLARE_METATYPE(KWin::KWinDesktopDataList)

// ***************** KWinDesktopData operators
inline QDBusArgument &operator <<(QDBusArgument &argument, const KWin::KWinDesktopData &desktop) {
    argument.beginStructure();
    argument << desktop.id << desktop.uuid << desktop.name;
    argument.endStructure();
    return argument;
}

inline const QDBusArgument &operator >>(const QDBusArgument &argument, KWin::KWinDesktopData &desktop) {
    argument.beginStructure();
    argument >> desktop.id >> desktop.uuid >> desktop.name;
    argument.endStructure();
    return argument;
}

// ***************** KWinDesktopDataList operators
inline QDBusArgument &operator <<(QDBusArgument &argument, const KWin::KWinDesktopDataList &desktopList) {
    argument.beginArray(qMetaTypeId<KWin::KWinDesktopData>());
    for (const auto &desktop : desktopList) {
        argument << desktop;
    }
    argument.endArray();
    return argument;
}

inline const QDBusArgument &operator >>(const QDBusArgument &argument, KWin::KWinDesktopDataList &desktopList) {
    argument.beginArray();
    desktopList.clear();
    while (!argument.atEnd()) {
        KWin::KWinDesktopData desktop;
        argument >> desktop;
        desktopList.append(desktop);
    }
    argument.endArray();
    return argument;
}
