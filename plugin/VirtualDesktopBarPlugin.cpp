// plugin/plugin.cpp
#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include "VirtualDesktopBar.hpp"

class VirtualDesktopBarPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri) override {
        Q_ASSERT(QString::fromUtf8(uri) == QStringLiteral("org.kde.plasma.virtualdesktopbar"));
        qmlRegisterType<VirtualDesktopBar>(uri, 1, 0, "VirtualDesktopBar");
    }
};

#include "VirtualDesktopBarPlugin.moc"
