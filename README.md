# Arc Launcher

<picture>
  <img alt="Arc Launcher Preview" src="docs/images/home.webp">
</picture>

[![Version](https://img.shields.io/github/v/release/meddouribadis/arclauncher?style=for-the-badge&color=7C4DFF&label=Version)](https://github.com/meddouribadis/arclauncher/releases/latest) [![Downloads](https://img.shields.io/github/downloads/meddouribadis/arclauncher/total?style=for-the-badge&color=7C4DFF&label=Downloads)](https://github.com/meddouribadis/arclauncher/releases) [![Stars](https://img.shields.io/github/stars/meddouribadis/arclauncher?style=for-the-badge&color=7C4DFF)](https://github.com/meddouribadis/arclauncher/stargazers) [![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/meddouribadis) [![Ko-fi](https://img.shields.io/badge/Support-Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/omeda)

**Arc Launcher** is an open-source launcher for Android TV, built as a fork of [LTvLauncher](https://github.com/LeanBitLab/LtvLauncher) (originally [FLauncher](https://gitlab.com/flauncher/flauncher)).

It adds a modern grid layout, customizable video and slideshow wallpapers, OLED screensaver protection, and remote-friendly navigation.

[![Get it on GitHub](https://img.shields.io/badge/Get_it_on-GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/meddouribadis/arclauncher/releases/latest) [![Downloader Code](https://img.shields.io/badge/Downloader_Code-6330120-FF6600?style=for-the-badge&logo=android&logoColor=white)](https://go.aftvnews.com/6330120)

## Join the Google Play Store beta

Arc Launcher is in closed beta on Google Play. To get early access to new builds and help shape what ships next,
join the beta group here with your Google Play email:

**[Arc Launcher Beta on Google Groups](https://groups.google.com/g/arc-launcher-beta/)**

Once you're in the group, you can enrol in the beta either way:

- **On the web** — open the [Google Play testing link](https://play.google.com/apps/testing/com.omeda.arc),
  sign in, and add the devices you want Arc on.
- **On Android** — follow the same testing link from the device itself, or find
  [Arc Launcher](https://play.google.com/store/apps/details?id=com.omeda.arc) in the Play Store app.

## Features

### Interface & Navigation
- **Grid Layout** - Clean smart TV app grid with configurable row and column sizing.
- **Watch Next** - Continue watching shows directly from a top-row carousel.
- **Remote Navigation** - High-visibility double-border focus indicators with smooth D-pad navigation.
- **Custom Categories** - Group apps into favorites or custom sections; reorder categories with Left/Right keys.
- **Quick Status Bar** - Displays time, daily data usage, and a shortcut to system Wi-Fi settings.
- **Auto-Hide Status Bar** - Hides the status bar when scrolling into the app grid to maximize screen space.
- **System Navigation Bar** - On devices with an on-screen back/home/recents bar, hide it over the launcher (swipe up to show) or reveal it only while the mouse pointer rests on the bottom edge.
- **Accent Colors** - Personalize the UI with multiple color presets.
- **App Icons** - Show banners, or each app's icon pulled from its package (full icon, adaptive foreground layer or themed monochrome) on a generic background: icon-tinted, wallpaper colors (picked from the wallpaper on screen and following each slideshow change), solid color, gradient, translucent or your own image. Card shadows include an accent glow on focus.
- **App Captions** - Choose when and where app names appear (below or on the card, always or on focus), with system or custom fonts, size, weight, case, alignment, color, pill/bar backgrounds, text shadows and box shadows. Custom `.ttf`/`.otf` fonts can be imported with a file manager or copied to `Android/data/com.omeda.arc/files/fonts/` (for example with `adb push`).
- **Multilingual** - Available in English, Spanish, Turkish, and Vietnamese.

### Wallpapers & Screensavers
- **Video Wallpapers** - Set animated video files (MP4/WebM) as the home screen background.
- **Slideshows** - Rotate wallpapers from custom subreddits or Unsplash categories with configurable intervals, or change to the next one on demand from settings (and, for Unsplash, over adb).
- **OLED Protection** - Pitch-black theme option and screensaver with position-shifting clock to prevent burn-in.
- **Dynamic Wallpapers** - Automatically switch wallpapers or enable dark mode based on the time of day.

### System & Tools
- **No Ads & No Tracking** - Completely open source with zero sponsored content or ads.
- **In-App Updater** - Check for new releases and read changelogs directly inside the app.
- **Sideloaded App Support** - Displays and launches non-TV Android apps without extra workarounds.
- **Brightness Scheduler (Experimental)** - Automatically adjust brightness based on time (requires ADB `WRITE_SETTINGS` permission).
- **Backup & Restore** - Save your settings and home screen layout to one JSON file, and restore them on this or another device.
- **Tuning over ADB** - Read and change any setting from a computer while the launcher is on screen. See [Backup, restore and tuning over ADB](#backup-restore-and-tuning-over-adb).

> [!NOTE]
> Because Android's `WallpaperManager` is not available on some Android TV devices, Arc Launcher manages its own wallpapers. Changing the wallpaper requires a file explorer installed on the device.

> [!TIP]
> **Video Wallpaper Performance:** Video wallpapers are loaded into memory for smooth playback. Use compressed clips (ideally under 10MB) on lower-powered TV sticks. If you experience UI stutter, disable the backdrop blur filter in settings.

## Screenshots

<table>
  <tr>
    <td align="center">Settings panel</td>
    <td align="center">Accent colors</td>
    <td align="center">Multiple wallpapers</td>
  </tr>
  <tr>
    <td><img src="docs/images/screen_settings1.png" width="100%" alt="Settings screen 1"/></td>
    <td><img src="docs/images/screen_settings2.png" width="100%" alt="Settings screen 2"/></td>
    <td><img src="docs/images/screen_settings3.png" width="100%" alt="Settings screen 3"/></td>
  </tr>
  <tr>
    <td align="center">Backdrop blur</td>
    <td align="center">Without blur</td>
    <td align="center">Custom banner</td>
  </tr>
  <tr>
    <td><img src="docs/images/screen_settings4.png" width="100%" alt="Settings screen 4"/></td>
    <td><img src="docs/images/screen_settings5.png" width="100%" alt="Settings screen 5"/></td>
    <td><img src="docs/images/screen_settings6.png" width="100%" alt="Settings screen 6"/></td>
  </tr>
  <tr>
    <td align="center">Home</td>
    <td align="center">Wallpaper Options</td>
    <td align="center">Watch Next</td>
  </tr>
  <tr>
    <td><img src="docs/images/home2.png" width="100%" alt="Another home page"/></td>
    <td><img src="docs/images/wallpapers_options.png" width="100%" alt="Different wallpaper options"/></td>
    <td><img src="docs/images/watch_next.png" width="100%" alt="Watch next section"/></td>
  </tr>
</table>

## Set Arc Launcher as default launcher

### Method 1: Remap the Home button

This is the "safer" and easiest way. Use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap the Home button of the remote to launch Arc Launcher.

### Method 2: Set Arc as the home activity over ADB

This is the recommended way to make Arc Launcher your actual home screen. It is a single command, it leaves the
stock launcher untouched, and it can be undone just as easily.

```shell
$ adb shell cmd package set-home-activity com.omeda.arc/.MainActivity
```

This assigns Arc to the system `HOME` role, so the Home button on the remote goes straight to Arc. Nothing gets
disabled, which means nothing needs to be re-enabled if you change your mind.

To check which launcher is currently set as home:

```shell
$ adb shell cmd package resolve-activity -c android.intent.category.HOME -a android.intent.action.MAIN
```

To go back to the stock launcher, point the home activity at it instead. List the launchers installed on the
box and copy the one you want back straight from the output:

```shell
$ adb shell cmd package query-activities -c android.intent.category.HOME -a android.intent.action.MAIN
```

```shell
$ adb shell cmd package set-home-activity <package>/<activity>
```

> [!NOTE]
> `set-home-activity` requires Android 8.1 or newer, and what it accepts differs by version. On Android 10 and
> above it assigns the `HOME` role through `RoleManager` and the package name alone is enough. On Android 8.1 to
> 9 it sets a preferred activity directly and needs the full `<package>/<activity>` form. On older systems, use
> Method 1 or the fallback below.

> [!TIP]
> On Android 15 and newer you can also clear the assignment entirely with
> `adb shell cmd package clear-package-preferred-activities`, which makes the system ask again on the next
> Home press.

### Method 3: GUI tools (no command line)

#### TV Box Tools (Android TV / Google TV)

TV Box Tools sets Arc Launcher as the home activity without typing ADB commands manually. Pick Arc
Launcher in the tool, and it installs the latest release and sets it as the default launcher. It runs on
Windows, macOS, Linux, Android phones, or directly in a TV browser:

- [Google Play](https://play.google.com/store/apps/details?id=com.tv.launcher.manager.adb.tvboxtools)
- [tvboxtools.com](https://tvboxtools.com)

#### Launcher Manager (Amazon Fire TV Stick / Fire OS)

On Amazon Fire TV devices, standard Android launcher switching commands are restricted by Fire OS.
Use **Launcher Manager (FireOS)** (available on [XDA Developers](https://xdaforums.com/t/app-firetv-noroot-launcher-manager-change-launcher-without-root.4176349/))
to set Arc Launcher as your default home screen and override the stock Fire TV launcher.

> [!NOTE]
> Third-party tools are not affiliated with or endorsed by this project. Review device permissions and wireless debugging access before running external management utilities.

### Fallback: Disable the default launcher

Use this only if Methods 2 and 3 do not work on your device. It is more invasive: it disables the stock
launcher, and it is the cause of the "YouTube" remote button issue described below.

> [!WARNING]
> **Disclaimer:** You are doing this at your own risk, and you'll be responsible in any case of malfunction on your device. The following commands have been tested on Chromecast with Google TV only and may differ on other devices.

Once the default launcher is disabled, press the Home button on the remote, and you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher

```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher

```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues

On Chromecast with Google TV (maybe others), the "YouTube" remote button will stop working if the default launcher is disabled. As a workaround, you can use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap it correctly.

## Backup, restore and tuning over ADB

**Settings → System → Backup & restore** saves one JSON file with your settings and the home screen layout: the sections in order, the apps in each, and which apps are hidden. Backups are saved in `Android/data/com.omeda.arc/files/backups/`. *Save a copy to…* puts one somewhere else, such as a USB drive, on devices that have a file picker.

Restoring replaces your settings and layout. The current ones are saved first as `arc-launcher-before-restore.json`, so restoring that file takes you back. Apps that are not installed are skipped, and installed apps the backup does not list are added to *All Apps*. Backups leave out wallpapers and other images, custom fonts (copy the `fonts` folder yourself) and your Unsplash and Reddit API keys.

While the launcher is running, its settings can also be read and changed from a computer, and the screen updates right away:

```bash
adb shell am broadcast -a com.omeda.arc.COMMAND -p com.omeda.arc --es cmd help
```

```bash
adb shell am broadcast -a com.omeda.arc.COMMAND -p com.omeda.arc --es cmd set --es key app_caption_font_size --es value 16
```

```bash
adb shell "am broadcast -a com.omeda.arc.COMMAND -p com.omeda.arc --es cmd set --es json '{\"app_caption_background\": \"pill\", \"app_icon_variant\": \"monochrome\"}'"
```

The answer is printed as `Broadcast completed: result=0, data="…"`. `result=1` means the command failed, and `data` says why. Values with spaces or quotes have to be quoted once more for the device's shell, as in the last example. Only adb can send these commands: the launcher accepts them only from senders holding Android's `DUMP` permission, which other apps cannot get. Debug builds use `com.omeda.arc.debug` instead of `com.omeda.arc`.

| Command | Arguments | Does |
|---|---|---|
| `help` | | Lists the commands, and every setting with the values it accepts |
| `list` | | Prints every setting as JSON, `null` meaning the default |
| `get` | `--es key <key>` | Prints one setting |
| `set` | `--es key <key> --es value <value>`, or `--es json '<object>'` | Changes settings |
| `reset` | `--es key <key>` | Puts a setting back to its default |
| `folder` | | Prints the backups folder, creating it if it is missing |
| `export` | `[--es path <file>]` | Saves a backup, by default in the backups folder, and prints its path |
| `import` | `--es path <file>`, or `--es json '<backup>'` | Restores a backup |
| `dump` | | Prints a backup |
| `next-photo` | | Shows the next Unsplash slideshow photo now and starts its interval over |

[`tool/arc-adb`](tool/arc-adb) runs these commands for you and handles the quoting. Its `pull` saves a backup and copies it to your computer, and `push` copies one to the device and restores it:

```bash
tool/arc-adb set app_caption_font_size 16
```

```bash
tool/arc-adb pull my-layout.json
```

```bash
tool/arc-adb push my-layout.json
```

## Contributing

Contributions are welcome! Please check our [Contributing Guidelines](CONTRIBUTING.md) to get started and learn about our commit conventions and Pull Request process.

## Sponsor & Support

If you enjoy using Arc Launcher and would like to support its ongoing development, consider sponsoring or buying a coffee! Your support helps keep the project active and maintained.

[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/meddouribadis) [![Ko-fi](https://img.shields.io/badge/Support-Ko--fi-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/omeda)

- **GitHub Sponsors**: [github.com/sponsors/meddouribadis](https://github.com/sponsors/meddouribadis)
- **Ko-fi**: [ko-fi.com/omeda](https://ko-fi.com/omeda)

## Credits and contributors

<a href="https://github.com/meddouribadis/arclauncher/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=meddouribadis/arclauncher" alt="Contributors" />
</a>

### Original Projects

- **[FLauncher](https://gitlab.com/flauncher/flauncher)** by [etienn01](https://github.com/etienn01) - The original project
- **[FLauncher (Fork)](https://github.com/osrosal/flauncher)** by [osrosal](https://github.com/osrosal) - Community fork with additional features
- **[LTvLauncher](https://github.com/LeanBitLab/LtvLauncher)** by [LeanBitLab](https://github.com/LeanBitLab) - The base for this fork
- **[Arc Launcher](https://github.com/meddouribadis/arclauncher)** by [meddouribadis](https://github.com/meddouribadis)

---
