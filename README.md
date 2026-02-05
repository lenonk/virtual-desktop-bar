# Virtual Desktop Bar (Plasma 6)

Virtual Desktop Bar is a KDE Plasma widget that provides a clean, configurable, text-based virtual desktop switcher. It replaces the default Pager with a compact desktop bar focused on clarity, customization, and modern Plasma 6 Wayland environments.

The widget displays desktops as labeled buttons with configurable indicators, styling, and behavior options. It also supports optional dynamic desktop management to automatically maintain a spare empty desktop.

This project is a modern continuation of earlier work, updated and maintained specifically for Plasma 6 on Wayland.

---

## Screenshots

### Adding, renaming, moving, and removing a desktop:
![Example 1](screenshots/1.gif)

### Various desktop label styles:
![Example 1](screenshots/2.gif)

### Various desktop indicator styles:
![Example 1](screenshots/3.gif)

### Partial support for vertical panels (still a work in progress):
![Example 1](screenshots/4.png)

*(Screenshots may change as the widget evolves.)*

---

## Features

### Desktop Switching
- Displays desktops as labeled buttons instead of thumbnails
- Quickly switch desktops with a click
- Optional scroll-wheel desktop switching
- Optional filtering by screen

### Indicator Styles
Multiple indicator styles are available:

- Edge line
- Side line
- Block
- Rounded block
- Full-size highlight

Indicator thickness, radius, colors, and behavior are configurable.

### Label Customization
Desktop labels support:

- Multiple label styles
- Custom formatting
- Maximum length limits
- Uppercase option
- Bold current desktop
- Dim inactive desktops
- Custom fonts and sizes
- Custom label colors

### Appearance Controls
- Adjustable button spacing and margins
- Optional uniform button sizing
- Configurable animations
- Add-desktop button support

### Dynamic Desktop Management
Optionally:
- Automatically maintain one empty desktop
- Create desktops as needed
- Remove unused desktops
- Optionally switch or rename newly created desktops
- Execute commands when desktops are created

---

## Installation

### From the AUR (Arch Linux)

The widget is available in the AUR:

`plasma6-applets-virtual-desktop-bar-wayland`

Install using your preferred AUR helper:

    paru -S plasma6-applets-virtual-desktop-bar-wayland

or:

    yay -S plasma6-applets-virtual-desktop-bar-wayland

After installation, add the widget to a panel or desktop via Plasma's widget picker.

---

### Manual Installation

Clone the repository:

    git clone https://github.com/lenonk/virtual-desktop-bar.git
    cd virtual-desktop-bar

Build and install:

    cmake -B build
    cmake --build build
    sudo cmake --install build

Restart plasmashell or re-login if the widget does not appear immediately.

---

## Usage

1. Add **Virtual Desktop Bar** to a panel or desktop.
2. Open widget settings to configure appearance and behavior.
3. Customize indicator styles, labels, colors, and dynamic desktop options to your liking.

---

## Compatibility

This widget is designed and tested for:

- KDE Plasma 6
- Wayland sessions

Wayland is required.

---

## Known Issues

Some Plasma panel visibility modes currently interfere with virtual desktop widgets. If desktops do not update correctly:

- Avoid panel modes that hide the panel automatically, or
- Use standard visibility modes.

Upstream Plasma behavior may change in future releases.

---

## Contributing

Bug reports, suggestions, and pull requests are welcome.

If reporting an issue, please include:
- Plasma version
- Distribution
- Steps to reproduce the problem

---

## License

This project is distributed under the GPL license. See repository files for details.

---

## Acknowledgements

This project builds upon earlier virtual desktop bar efforts within the KDE community and continues development for modern Plasma environments.
