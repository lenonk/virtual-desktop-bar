cmake_minimum_required(VERSION 3.1)
project(VirtualDesktopBar)

set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_DEBUG "-g")
#set(CMAKE_CXX_FLAGS_RELEASE "-O3")

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "/usr")
endif()

if(NOT KDE_INSTALL_QMLDIR)
    file(STRINGS /etc/os-release distro REGEX "^NAME=.*$")
    if(distro MATCHES ".*Ubuntu.*")
        set(KDE_INSTALL_QMLDIR "/usr/lib/x86_64-linux-gnu/qt6/qml")
    endif()

    file(STRINGS /etc/os-release distro REGEX "^NAME=.*$")
    if(distro MATCHES ".*openSUSE.*")
        set(KDE_INSTALL_QMLDIR "/usr/lib64/qt6/qml")
    endif()

    file(STRINGS /etc/os-release distro REGEX "^NAME=.*$")
    if(distro MATCHES ".*Arch|Manjaro|Solus.*")
        set(KDE_INSTALL_QMLDIR "/usr/lib/qt/qml")
    endif()
endif()

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECompilerSettings)
include(KDECMakeSettings)
include(ECMInstallIcons)

set(REQUIRED_QT_VERSION 6.2.0)
set(KF6_MIN_VERSION 6.0.0)

find_package(Qt6 ${REQUIRED_QT_VERSION}
             CONFIG REQUIRED
             Qml)

find_package(KF6 ${KF6_MIN_VERSION}
             REQUIRED COMPONENTS
             WindowSystem
             GlobalAccel
             XmlGui)
find_package(Plasma "6.0.0" REQUIRED)

find_package(KWayland "6.0.0" CONFIG REQUIRED)
set_package_properties(KWayland PROPERTIES TYPE OPTIONAL )
add_feature_info("KWayland" KWayland_FOUND "Required for the awesome Wayland on Qt demo")

find_package(LibTaskManager "5.24.0" # Replace literal appropriate with variable
             CONFIG REQUIRED)

plasma_install_package(package org.kde.plasma.virtualdesktopbar)

include_directories("/usr/include/taskmanager" ${KF6WaylandClient_INCLUDE_DIRS}) # Replace literal with appropriate variable

set(virtualdesktopbar_SRCS
    plugin/DesktopInfo.cpp
    plugin/VirtualDesktopBar.cpp
    plugin/VirtualDesktopBarPlugin.cpp
)

add_library(virtualdesktopbar SHARED ${virtualdesktopbar_SRCS})

target_link_libraries(virtualdesktopbar
                      Qt6::Qml
                      Plasma::Plasma
                      Plasma::KWaylandClient
                      KF6::WindowSystem
                      KF6::GlobalAccel
                      KF6::XmlGui
                      PW::LibTaskManager)

install(TARGETS virtualdesktopbar DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/virtualdesktopbar)
install(FILES plugin/qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/plasma/virtualdesktopbar)

ecm_install_icons(ICONS icons/sc-apps-virtualdesktopbar.svg DESTINATION ${ICON_INSTALL_DIR})
