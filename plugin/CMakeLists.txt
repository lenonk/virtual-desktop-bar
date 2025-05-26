# plugin/CMakeLists.txt
set(virtualdesktopbar_SRCS
        VirtualDesktopBar.cpp
        VirtualDesktopBarPlugin.cpp
        VirtualDesktopBar.hpp
)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_library(virtualdesktopbar SHARED ${virtualdesktopbar_SRCS})

target_include_directories(virtualdesktopbar PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(virtualdesktopbar
        Qt::Core
        Qt::DBus
        Qt::Qml
        Qt::Widgets
        KF6::I18n
        KF6::Service
        KF6::WindowSystem
        KWin::kwin
        Plasma::Plasma
        Plasma::Activities
)

install(TARGETS virtualdesktopbar DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/virtualdesktopbar)
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/virtualdesktopbar)
