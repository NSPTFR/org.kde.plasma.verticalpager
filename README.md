# org.kde.plasma.verticalpager
rewrite of org.kde.plasma.pager to show pager vertically instead of horizontally to work with vertical sidebars,
There is an additional option when used as a desktop component, to allow it to stay on top during fullscreen mode.

## Features

- Desktops stacked vertically in vertical panels and on the desktop, side by side in horizontal panels
- Tiles follow the screen's aspect ratio and show outlines of the windows on each desktop, with their application icons
- Click a tile to switch to that desktop, or scroll the mouse wheel to go through them
- Tooltips list the windows on each desktop
- Add or remove desktops from the context menu
- **Stay on top of fullscreen windows** (desktop widget only): while a fullscreen window is shown on the
  widget's screen, a copy of the pager is drawn in a layer-shell overlay at the widget's position

Requires Plasma 6 on Wayland (the fullscreen overlay relies on layer-shell).

## Install

```sh
kpackagetool6 -t Plasma/Applet -i .      # first install
kpackagetool6 -t Plasma/Applet -u .      # upgrade
```

Then add **Vertical Pager** from the *Add Widgets…* panel. To try it out without a panel:

```sh
plasmawindowed org.kde.plasma.verticalpager
```

## Translations

Translations live in `po/<lang>.po` (French is included). After adding or changing one, rebuild the
catalogs bundled in the package, then reinstall:

```sh
python3 po/compile.py
kpackagetool6 -t Plasma/Applet -u .
```

`po/compile.py` writes `contents/locale/<lang>/LC_MESSAGES/plasma_applet_org.kde.plasma.verticalpager.mo`,
where Plasma looks for the widget's translations; it does not need gettext to be installed.
