# Yeove's Firefox Sidebery CSS Tweaks

This is my custom CSS for Firefox.
<br>It's pretty similar to Firefox's native vertical tabs, but with auto hover / tab search / inline image previews / custom keybinds using the sidebery addon

## Overview

```mermaid
flowchart LR
    A["userChrome.css<br/>(this repo)"] --> B["profile-id/chrome<br>folder found via<br>about:support → Open Folder"]
    C["Sidebery_Settings.json<br/>(this repo)"] --> D["Sidebery Settings →<br/>Help → Import addon data"]
```

---

## Prerequisites
Install all of this before following the guide

1. [Firefox](https://www.firefox.com/en-CA/download/all/) any modern version
2. [Sidebery](https://addons.mozilla.org/firefox/addon/sidebery/) extension for vertical tabs
3. [Adaptive Tab Bar Colour](https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour/) extension for dynamic sidebar colours

---

## Setup Guide

### Step 1: Enable userChrome.css support in Firefox

1. Open a new tab and go to `about:config`
2. Search for `toolkit.legacyUserProfileCustomizations.stylesheets`
3. Set it to `true`
<br><a href="README FILES/firefox-enable-css.gif" target="_blank">
  <img src="README FILES/firefox-enable-css.gif" alt="Firefox enable userChrome.css support" width="600">
</a>

### Step 2: Install userChrome.css

1. Open `about:support`
2. Find the **Profile Folder** row → click **Open Folder**
    <br>This will open a folder on your desktop:
- `Windows:`  `C:\Users\<YourUsername>\AppData\Roaming\Mozilla\Firefox\Profiles\<profile-id>`
- `Linux:`    `~/.mozilla/firefox/<profile-id>`
- `macOS:`    `~/Library/Application Support/Firefox/Profiles/<profile-id>` 
3. Drag the **chrome** folder from this repo into the **profile-id** folder
    <a href="README FILES/firefox-chrome-folder.gif" target="_blank">
      <img src="README FILES/firefox-chrome-folder.gif" alt="Firefox open profile folder" width="800">
    </a>
4. Fully close Firefox by clicking the **☰** menu on the top right, then press **Exit**, or **Ctrl + Shift + Q**
<br><a href="README FILES/firefox-close.gif" target="_blank">
  <img src="README FILES/firefox-close.gif" alt="Closing Firefox via menu" width="200">
</a>
5. Relaunch Firefox

   &nbsp;
  
   > You should now have custom .css enabled

   &nbsp;
  
### Step 3: Import Sidebery settings

1. Click the Sidebery icon (or press `F1`) to expand the sidebar
2. Click the ⚙️ gear icon on the top right to open Sidebery Settings
3. In the left menu, click **Help**
4. Click **Import addon data**
5. Select `Sidebery_Settings.json` from this repo
6. On the new window that popped up; click **Import addon data**
<br><a href="README FILES/sidebery-import-settings.gif" target="_blank">
  <img src="README FILES/sidebery-import-settings.gif" alt="Sidebery import settings" width="600">
</a>

> Importing will overwrite your existing Sidebery settings<br>If you've already set things up the way you like, export your current settings first via<br>Settings → Help → Export addon data

## Optional Tweaks

###  Step 4: Move Sidebery to the right side of the window

1. Right-click the Sidebery icon in your toolbar
2. Select **"Move sidebar to right"**
<br>
<br>Or in `about:config`, set `sidebar.position_start` to `false`
<br><a href="README FILES/sidebery-right-side.gif" target="_blank">
  <img src="README FILES/sidebery-right-side.gif" alt="Sidebery move sidebar to right" width="600">
</a>

### Additional Notes

**Credits - stuff I lovingly stole from people:**
- Base config by [CLHowell on Pastebin](https://pastebin.com/6z7QU7ps)
- Reddit [r/FirefoxCSS](https://www.reddit.com/r/FirefoxCSS/comments/1rno75d/sidebery_expandonhover/)

---

## License

Do whatever you wanna do. Fork & adapt as much as you want
