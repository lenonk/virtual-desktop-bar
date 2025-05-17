
cmake_minimum_required(VERSION 3.27)

project(virtual-desktop-bar)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_MIN_VERSION "6.4.0")
set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core DBus Qml Widgets)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS I18n Service WindowSystem)
find_package(Plasma ${KF6_MIN_VERSION} REQUIRED)
find_package(KWin REQUIRED)

add_subdirectory(plugin)
plasma_install_package(package org.kde.plasma.virtualdesktopbar)