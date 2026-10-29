/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.omeda.arc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.pm.*;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.drawable.AdaptiveIconDrawable;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.util.Pair;
import android.view.View;
import android.media.tv.TvContract;
import android.database.Cursor;
import android.Manifest;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import android.app.usage.NetworkStats;
import android.app.usage.NetworkStatsManager;
import android.app.AppOpsManager;
import android.os.RemoteException;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformPlugin;

import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletionService;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class MainActivity extends FlutterActivity {
    private final String METHOD_CHANNEL = "me.efesser.flauncher/method";
    private final String APPS_EVENT_CHANNEL = "me.efesser.flauncher/event_apps";
    private final String NETWORK_EVENT_CHANNEL = "me.efesser.flauncher/event_network";
    private final String COMMANDS_CHANNEL = "me.efesser.flauncher/commands";
    private static final String PERMISSION_READ_TV_LISTINGS = "android.permission.READ_TV_LISTINGS";
    private static final int REQUEST_CODE_READ_TV_LISTINGS = 1001;
    private static final String COLUMN_ASPECT_RATIO = "aspect_ratio";
    private static final int REQUEST_CODE_PICK_FONT = 1002;
    private static final int REQUEST_CODE_OPEN_BACKUP = 1003;
    private static final int REQUEST_CODE_SAVE_BACKUP = 1004;
    private static final int MAX_BACKUP_SIZE = 8 * 1024 * 1024;
    // App card icons are drawn up to ~200 physical pixels tall on 1080p TVs.
    private static final int ICON_VARIANT_RENDER_SIZE = 256;

    private final ExecutorService iconExecutor = Executors.newSingleThreadExecutor();
    private MethodChannel.Result pendingFontPickResult;
    private String pendingFontPickDirectory;
    private MethodChannel.Result pendingOpenBackupResult;
    private MethodChannel.Result pendingSaveBackupResult;
    private String pendingSaveBackupContent;

    private MethodChannel commandsChannel;
    private BroadcastReceiver commandReceiver;

    // "visible", "hidden" or "bottomEdge" (hidden, revealed while the pointer rests on the bottom edge).
    private String navigationBarMode = "visible";
    private boolean navigationBarRevealed = false;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

        new MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "getApplications" -> result.success(getApplications());
                case "getApplicationBanner" -> result.success(getApplicationBanner(call.arguments()));
                case "getApplicationIcon" -> result.success(getApplicationIcon(call.arguments()));
                case "getApplicationIconVariant" -> {
                    String packageName = call.argument("packageName");
                    String variant = call.argument("variant");
                    iconExecutor.execute(() -> {
                        Map<String, Object> icon = getApplicationIconVariant(packageName, variant);
                        runOnUiThread(() -> result.success(icon));
                    });
                }
                case "pickFontFile" -> pickFontFile(call.argument("directory"), result);
                case "openBackupFile" -> openBackupFile(result);
                case "saveBackupFile" -> saveBackupFile(call.argument("name"), call.argument("content"), result);
                case "setNavigationBarMode" -> {
                    navigationBarMode = call.arguments();
                    navigationBarRevealed = false;
                    applyNavigationBarState();
                    result.success(null);
                }
                case "setNavigationBarRevealed" -> {
                    navigationBarRevealed = Boolean.TRUE.equals(call.arguments());
                    applyNavigationBarState();
                    result.success(null);
                }
                case "applicationExists" -> result.success(applicationExists(call.arguments()));
                case "launchActivityFromAction" -> result.success(launchActivityFromAction(call.arguments()));
                case "launchApp" -> result.success(launchApp(call.arguments()));
                case "openSettings" -> result.success(openSettings());
                case "installApk" -> result.success(installApk(call.arguments()));
                case "requestInstallUnknownAppsPermission" -> {
                    requestInstallUnknownAppsPermission();
                    result.success(null);
                }
                case "openScreensaverSettings" -> result.success(openScreensaverSettings());
                case "openAppInfo" -> result.success(openAppInfo(call.arguments()));
                case "uninstallApp" -> result.success(uninstallApp(call.arguments()));
                case "isDefaultLauncher" -> result.success(isDefaultLauncher());
                case "checkForGetContentAvailability" -> result.success(checkForGetContentAvailability());
                case "startAmbientMode" -> result.success(startAmbientMode());
                case "getActiveNetworkInformation" -> result.success(getActiveNetworkInformation());
                case "getDailyWifiUsage" -> {
                    long usage = getDailyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getWeeklyWifiUsage" -> {
                    long usage = getWeeklyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "getMonthlyWifiUsage" -> {
                    long usage = getMonthlyWifiUsage();
                    if (usage == -1) {
                        result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                    } else {
                        result.success(usage);
                    }
                }
                case "checkUsageStatsPermission" -> result.success(checkUsageStatsPermission());
                case "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission();
                    result.success(null);
                }
                case "checkWriteSettingsPermission" -> result.success(checkWriteSettingsPermission());
                case "requestWriteSettingsPermission" -> {
                    requestWriteSettingsPermission();
                    result.success(null);
                }
                case "setSystemBrightness" -> {
                    int brightness = call.argument("brightness");
                    result.success(setSystemBrightness(brightness));
                }
                case "openWifiSettings" -> result.success(openWifiSettings());
                case "getMediaStoreImages" -> result.success(getMediaStoreImages());
                case "getMediaStoreVideos" -> result.success(getMediaStoreVideos());
                case "getMediaStoreVideoThumbnail" -> {
                    Number id = call.argument("id");
                    String path = call.argument("path");
                    result.success(getMediaStoreVideoThumbnail(
                        id != null ? id.longValue() : -1, path));
                }
                case "checkMediaPermissions" -> result.success(checkMediaPermissions());
                case "requestMediaPermissions" -> {
                    requestMediaPermissions();
                    result.success(null);
                }
                case "checkWatchNextPermission" -> result.success(checkWatchNextPermission());
                case "requestWatchNextPermission" -> {
                    requestWatchNextPermission();
                    result.success(null);
                }
                case "getWatchNextItems" -> {
                    int limit = call.arguments() != null ? (int) call.arguments() : 10;
                    result.success(getWatchNextItems(limit));
                }
                case "launchWatchNextItem" -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> args = (Map<String, Object>) call.arguments();
                    if (args != null) {
                        String packageName = (String) args.get("packageName");
                        String contentId = (String) args.get("contentId");
                        String action = (String) args.get("action");
                        result.success(launchWatchNextItem(packageName, contentId, action));
                    } else {
                        result.success(false);
                    }
                }
                case "loadContentUriImage" -> {
                    String contentUri = (String) call.arguments();
                    if (contentUri != null) {
                        result.success(loadContentUriImage(contentUri));
                    } else {
                        result.success(new byte[0]);
                    }
                }
                default -> throw new IllegalArgumentException("Unknown method: " + call.method);
            }
        });

        new EventChannel(messenger, APPS_EVENT_CHANNEL).setStreamHandler(
                new LauncherAppsEventStreamHandler(this));

        new EventChannel(messenger, NETWORK_EVENT_CHANNEL).setStreamHandler(
                new NetworkEventStreamHandler(this));

        commandsChannel = new MethodChannel(messenger, COMMANDS_CHANNEL);
        registerCommandReceiver();
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (commandReceiver != null) {
            unregisterReceiver(commandReceiver);
            commandReceiver = null;
        }
        super.cleanUpFlutterEngine(flutterEngine);
    }

    /**
     * Passes {@code adb shell am broadcast -a <package>.COMMAND --es cmd ...} on to Dart, and answers with its
     * output as the broadcast result: result=0 when the command worked, 1 when it failed. Only senders holding
     * DUMP get through, which are the adb shell and the system, not other apps.
     */
    @SuppressWarnings("deprecation")
    private void registerCommandReceiver() {
        commandReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Map<String, String> arguments = new HashMap<>();
                Bundle extras = intent.getExtras();
                if (extras != null) {
                    for (String key : extras.keySet()) {
                        Object value = extras.get(key);
                        arguments.put(key, value != null ? String.valueOf(value) : null);
                    }
                }

                PendingResult pendingResult = goAsync();
                commandsChannel.invokeMethod("run", arguments, new MethodChannel.Result() {
                    @Override
                    public void success(Object reply) {
                        Map<?, ?> map = reply instanceof Map ? (Map<?, ?>) reply : new HashMap<>();
                        boolean ok = Boolean.TRUE.equals(map.get("ok"));
                        pendingResult.setResult(ok ? 0 : 1, String.valueOf(map.get("output")), null);
                        pendingResult.finish();
                    }

                    @Override
                    public void error(@NonNull String code, String message, Object details) {
                        pendingResult.setResult(1, "error: " + message, null);
                        pendingResult.finish();
                    }

                    @Override
                    public void notImplemented() {
                        pendingResult.setResult(1, "error: the launcher is still starting, try again in a moment", null);
                        pendingResult.finish();
                    }
                });
            }
        };
        ContextCompat.registerReceiver(this, commandReceiver, new IntentFilter(getPackageName() + ".COMMAND"),
                Manifest.permission.DUMP, null, ContextCompat.RECEIVER_EXPORTED);
    }

    private List<Map<String, Serializable>> getApplications() {
        ExecutorService executor = Executors.newFixedThreadPool(4);
        CompletionService<Pair<Boolean, List<ResolveInfo>>> queryIntentActivitiesCompletionService = new ExecutorCompletionService<>(
                executor);
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(false, queryIntentActivities(false)));
        queryIntentActivitiesCompletionService.submit(() -> Pair.create(true, queryIntentActivities(true)));
        List<ResolveInfo> tvActivitiesInfo = null;
        List<ResolveInfo> nonTvActivitiesInfo = null;

        int completed = 0;
        while (completed < 2) {
            try {
                var activitiesInfo = queryIntentActivitiesCompletionService.take().get();

                if (!activitiesInfo.first) {
                    tvActivitiesInfo = activitiesInfo.second;
                } else {
                    nonTvActivitiesInfo = activitiesInfo.second;
                }
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                completed += 1;
            }
        }

        CompletionService<Map<String, Serializable>> completionService = new ExecutorCompletionService<>(executor);

        List<Map<String, Serializable>> applications = new ArrayList<>(
                tvActivitiesInfo.size() + nonTvActivitiesInfo.size());

        boolean settingsPresent = false;
        int appCount = 0;
        for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
            if (!settingsPresent) {
                settingsPresent = tvActivityInfo.activityInfo.packageName.equals("com.android.tv.settings");
            }

            completionService.submit(() -> buildAppMap(tvActivityInfo.activityInfo, false, null));
            appCount += 1;
        }

        for (ResolveInfo nonTvActivityInfo : nonTvActivitiesInfo) {
            boolean nonDuplicate = true;

            if (!settingsPresent) {
                settingsPresent = nonTvActivityInfo.activityInfo.packageName.equals("com.android.settings");
            }

            for (ResolveInfo tvActivityInfo : tvActivitiesInfo) {
                if (tvActivityInfo.activityInfo.packageName.equals(nonTvActivityInfo.activityInfo.packageName)) {
                    nonDuplicate = false;
                    break;
                }
            }

            if (nonDuplicate) {
                appCount += 1;
                completionService.submit(() -> buildAppMap(nonTvActivityInfo.activityInfo, true, null));
            }
        }

        while (appCount > 0) {
            try {
                Future<Map<String, Serializable>> appMap = completionService.take();
                applications.add(appMap.get());
            } catch (InterruptedException | ExecutionException ignored) {
            } finally {
                appCount -= 1;
            }
        }

        executor.shutdown();

        if (!settingsPresent) {
            PackageManager packageManager = getPackageManager();
            Intent settingsIntent = new Intent(Settings.ACTION_SETTINGS);
            ActivityInfo activityInfo = settingsIntent.resolveActivityInfo(packageManager, 0);

            if (activityInfo != null) {
                applications.add(buildAppMap(activityInfo, false, Settings.ACTION_SETTINGS));
            }
        }

        return applications;
    }

    public Map<String, Serializable> getApplication(String packageName) {
        Map<String, Serializable> map = Map.of();
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        if (intent != null) {
            ActivityInfo activityInfo = intent.resolveActivityInfo(getPackageManager(), 0);

            if (activityInfo != null) {
                map = buildAppMap(activityInfo, false, null);
            }
        }

        return map;
    }

    private byte[] getApplicationBanner(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            // Many TV apps (e.g. Free TV, S0undTV) declare android:banner on their leanback activity
            // only; getActivityBanner falls back to the application banner when the activity has none.
            Intent leanbackIntent = packageManager.getLeanbackLaunchIntentForPackage(packageName);
            Drawable drawable = leanbackIntent != null ? packageManager.getActivityBanner(leanbackIntent) : null;
            if (drawable == null) {
                drawable = info.loadBanner(packageManager);
            }

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    private byte[] getApplicationIcon(String packageName) {
        byte[] imageBytes = new byte[0];

        PackageManager packageManager = getPackageManager();
        try {
            ApplicationInfo info = packageManager.getApplicationInfo(packageName, 0);
            Drawable drawable = info.loadIcon(packageManager);

            if (drawable != null) {
                imageBytes = drawableToByteArray(drawable);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        return imageBytes;
    }

    /**
     * Renders the launcher icon of [packageName] for app cards drawn on a generic background.
     *
     * [variant] is "full" (the icon as the system shows it), "foreground" (the foreground layer
     * of an adaptive icon, without its own background) or "monochrome" (the themed icon layer,
     * Android 13+). When the requested layer is missing the full icon is returned instead, and
     * the returned "variant" says which one was actually rendered.
     */
    private Map<String, Object> getApplicationIconVariant(String packageName, String variant) {
        Map<String, Object> result = new HashMap<>();
        result.put("bytes", new byte[0]);
        result.put("variant", "full");

        Drawable icon = loadHighResIcon(packageName);
        if (icon == null) {
            return result;
        }

        Bitmap fullBitmap = renderDrawable(icon, ICON_VARIANT_RENDER_SIZE);
        Bitmap bitmap = fullBitmap;
        String renderedVariant = "full";

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && icon instanceof AdaptiveIconDrawable adaptiveIcon) {
            Drawable layer = null;
            if ("monochrome".equals(variant) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                layer = adaptiveIcon.getMonochrome();
                if (layer != null) {
                    layer = layer.mutate();
                    layer.setColorFilter(new PorterDuffColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN));
                    renderedVariant = "monochrome";
                }
            } else if ("foreground".equals(variant)) {
                layer = adaptiveIcon.getForeground();
                if (layer != null) {
                    renderedVariant = "foreground";
                }
            }

            if (layer != null) {
                bitmap = renderAdaptiveIconLayer(layer, ICON_VARIANT_RENDER_SIZE);
            }
        }

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        result.put("bytes", stream.toByteArray());
        result.put("variant", renderedVariant);
        // Sampled from the full icon: brand colours often live in the adaptive background layer.
        result.put("color", dominantColor(fullBitmap));
        return result;
    }

    /** Loads the launch activity icon (leanback first) at the highest available density. */
    private Drawable loadHighResIcon(String packageName) {
        PackageManager packageManager = getPackageManager();
        Intent launchIntent = packageManager.getLeanbackLaunchIntentForPackage(packageName);
        if (launchIntent == null) {
            launchIntent = packageManager.getLaunchIntentForPackage(packageName);
        }

        try {
            ResolveInfo resolveInfo = launchIntent != null ? packageManager.resolveActivity(launchIntent, 0) : null;
            if (resolveInfo != null && resolveInfo.activityInfo != null) {
                ActivityInfo activityInfo = resolveInfo.activityInfo;
                int iconResource = activityInfo.getIconResource();
                if (iconResource != 0) {
                    try {
                        Resources resources = packageManager.getResourcesForApplication(activityInfo.applicationInfo);
                        Drawable drawable = resources.getDrawableForDensity(iconResource, DisplayMetrics.DENSITY_XXXHIGH, null);
                        if (drawable != null) {
                            return drawable;
                        }
                    } catch (Resources.NotFoundException ignored) {
                    }
                }
                return activityInfo.loadIcon(packageManager);
            }
            return packageManager.getApplicationIcon(packageName);
        } catch (PackageManager.NameNotFoundException ignored) {
            return null;
        }
    }

    private Bitmap renderDrawable(Drawable drawable, int size) {
        int width = drawable.getIntrinsicWidth();
        int height = drawable.getIntrinsicHeight();
        int bitmapWidth = size;
        int bitmapHeight = size;
        if (width > 0 && height > 0 && width != height) {
            // Keep the aspect ratio of non-square legacy icons.
            if (width > height) {
                bitmapHeight = Math.max(1, size * height / width);
            } else {
                bitmapWidth = Math.max(1, size * width / height);
            }
        }

        Bitmap bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, bitmapWidth, bitmapHeight);
        drawable.draw(canvas);
        return bitmap;
    }

    /**
     * Adaptive icon layers are 108dp squares of which only the inner 72dp is ever visible, so the
     * layer is drawn oversized to crop the reserved 18dp bleed on each side.
     */
    private Bitmap renderAdaptiveIconLayer(Drawable layer, int size) {
        Bitmap bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        int bleed = size / 4;
        layer.setBounds(-bleed, -bleed, size + bleed, size + bleed);
        layer.draw(canvas);
        return bitmap;
    }

    /** Average of the icon's opaque pixels, weighted towards saturated ones. */
    private int dominantColor(Bitmap bitmap) {
        Bitmap sample = Bitmap.createScaledBitmap(bitmap, 32, 32, true);
        double red = 0, green = 0, blue = 0, totalWeight = 0;
        float[] hsv = new float[3];
        for (int y = 0; y < sample.getHeight(); y++) {
            for (int x = 0; x < sample.getWidth(); x++) {
                int pixel = sample.getPixel(x, y);
                int alpha = Color.alpha(pixel);
                if (alpha < 128) {
                    continue;
                }
                Color.colorToHSV(pixel, hsv);
                double weight = 0.15 + hsv[1] * hsv[2];
                red += Color.red(pixel) * weight;
                green += Color.green(pixel) * weight;
                blue += Color.blue(pixel) * weight;
                totalWeight += weight;
            }
        }
        if (totalWeight == 0) {
            return Color.DKGRAY;
        }
        return Color.rgb((int) (red / totalWeight), (int) (green / totalWeight), (int) (blue / totalWeight));
    }

    /**
     * Lets the user pick a font file with whatever handles GET_CONTENT (a file manager on most
     * TVs) and copies it into [directory]. Answers with the copied file path, or null.
     */
    private void pickFontFile(String directory, MethodChannel.Result result) {
        if (pendingFontPickResult != null) {
            pendingFontPickResult.success(null);
        }

        Intent intent = new Intent(Intent.ACTION_GET_CONTENT)
                .setType("*/*")
                .addCategory(Intent.CATEGORY_OPENABLE)
                .putExtra(Intent.EXTRA_MIME_TYPES, new String[]{
                        "font/ttf", "font/otf", "font/sfnt", "application/x-font-ttf",
                        "application/x-font-otf", "application/font-sfnt", "application/octet-stream"});

        if (intent.resolveActivity(getPackageManager()) == null) {
            result.success(null);
            return;
        }

        pendingFontPickResult = result;
        pendingFontPickDirectory = directory;
        try {
            startActivityForResult(intent, REQUEST_CODE_PICK_FONT);
        } catch (Exception e) {
            pendingFontPickResult = null;
            result.success(null);
        }
    }

    /**
     * Lets the user pick a backup with whatever handles GET_CONTENT. Answers with its text, or null when
     * cancelled; fails with "unavailable" when nothing on the device can pick files.
     */
    private void openBackupFile(MethodChannel.Result result) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT)
                .setType("*/*")
                .addCategory(Intent.CATEGORY_OPENABLE)
                .putExtra(Intent.EXTRA_MIME_TYPES, new String[]{
                        "application/json", "text/plain", "application/octet-stream"});

        if (intent.resolveActivity(getPackageManager()) == null) {
            result.error("unavailable", "No app on this device can open files", null);
            return;
        }
        if (pendingOpenBackupResult != null) {
            pendingOpenBackupResult.success(null);
        }
        pendingOpenBackupResult = result;
        try {
            startActivityForResult(intent, REQUEST_CODE_OPEN_BACKUP);
        } catch (Exception e) {
            pendingOpenBackupResult = null;
            result.error("unavailable", e.getMessage(), null);
        }
    }

    private void onBackupFileOpened(Uri uri) {
        MethodChannel.Result result = pendingOpenBackupResult;
        pendingOpenBackupResult = null;
        if (result == null) {
            return;
        }
        if (uri == null) {
            result.success(null);
            return;
        }

        iconExecutor.execute(() -> {
            String text = null;
            String error = null;
            try (InputStream input = getContentResolver().openInputStream(uri)) {
                if (input == null) {
                    throw new IOException("The file cannot be opened");
                }
                ByteArrayOutputStream output = new ByteArrayOutputStream();
                byte[] buffer = new byte[16 * 1024];
                int read;
                while ((read = input.read(buffer)) != -1) {
                    output.write(buffer, 0, read);
                    if (output.size() > MAX_BACKUP_SIZE) {
                        throw new IOException("The file is too large to be a backup");
                    }
                }
                text = new String(output.toByteArray(), StandardCharsets.UTF_8);
            } catch (Exception e) {
                error = e.getMessage();
            }
            String finalText = text;
            String finalError = error;
            runOnUiThread(() -> {
                if (finalError != null) {
                    result.error("io", finalError, null);
                } else {
                    result.success(finalText);
                }
            });
        });
    }

    /**
     * Lets the user choose where to save a copy of a backup (CREATE_DOCUMENT). Answers true once written and
     * false when cancelled; fails with "unavailable" when nothing on the device can save files.
     */
    private void saveBackupFile(String name, String content, MethodChannel.Result result) {
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT)
                .setType("application/json")
                .addCategory(Intent.CATEGORY_OPENABLE)
                .putExtra(Intent.EXTRA_TITLE, name);

        if (intent.resolveActivity(getPackageManager()) == null) {
            result.error("unavailable", "No app on this device can save files", null);
            return;
        }
        if (pendingSaveBackupResult != null) {
            pendingSaveBackupResult.success(false);
        }
        pendingSaveBackupResult = result;
        pendingSaveBackupContent = content;
        try {
            startActivityForResult(intent, REQUEST_CODE_SAVE_BACKUP);
        } catch (Exception e) {
            pendingSaveBackupResult = null;
            pendingSaveBackupContent = null;
            result.error("unavailable", e.getMessage(), null);
        }
    }

    private void onBackupFileCreated(Uri uri) {
        MethodChannel.Result result = pendingSaveBackupResult;
        String content = pendingSaveBackupContent;
        pendingSaveBackupResult = null;
        pendingSaveBackupContent = null;
        if (result == null) {
            return;
        }
        if (uri == null || content == null) {
            result.success(false);
            return;
        }

        iconExecutor.execute(() -> {
            String error = null;
            try (OutputStream output = getContentResolver().openOutputStream(uri, "w")) {
                if (output == null) {
                    throw new IOException("The file cannot be written");
                }
                output.write(content.getBytes(StandardCharsets.UTF_8));
            } catch (Exception e) {
                error = e.getMessage();
            }
            String finalError = error;
            runOnUiThread(() -> {
                if (finalError != null) {
                    result.error("io", finalError, null);
                } else {
                    result.success(true);
                }
            });
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Uri resultUri = resultCode == RESULT_OK && data != null ? data.getData() : null;
        if (requestCode == REQUEST_CODE_OPEN_BACKUP) {
            onBackupFileOpened(resultUri);
            return;
        }
        if (requestCode == REQUEST_CODE_SAVE_BACKUP) {
            onBackupFileCreated(resultUri);
            return;
        }
        if (requestCode != REQUEST_CODE_PICK_FONT || pendingFontPickResult == null) {
            return;
        }

        MethodChannel.Result result = pendingFontPickResult;
        String directory = pendingFontPickDirectory;
        pendingFontPickResult = null;
        pendingFontPickDirectory = null;

        Uri uri = data != null ? data.getData() : null;
        if (resultCode != RESULT_OK || uri == null || directory == null) {
            result.success(null);
            return;
        }

        iconExecutor.execute(() -> {
            String path = copyFontFile(uri, directory);
            runOnUiThread(() -> result.success(path));
        });
    }

    private String copyFontFile(Uri uri, String directory) {
        String name = null;
        try (Cursor cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                name = cursor.getString(0);
            }
        } catch (Exception ignored) {
        }
        if (name == null) {
            name = uri.getLastPathSegment();
        }
        if (name == null) {
            name = "font.ttf";
        }
        name = new File(name).getName().replaceAll("[^A-Za-z0-9._ -]", "_");
        String lowerName = name.toLowerCase();
        if (!lowerName.endsWith(".ttf") && !lowerName.endsWith(".otf")) {
            return null;
        }

        File directoryFile = new File(directory);
        if (!directoryFile.exists() && !directoryFile.mkdirs()) {
            return null;
        }
        File target = new File(directoryFile, name);
        try (InputStream input = getContentResolver().openInputStream(uri);
             OutputStream output = new FileOutputStream(target)) {
            if (input == null) {
                return null;
            }
            byte[] buffer = new byte[16 * 1024];
            int read;
            while ((read = input.read(buffer)) != -1) {
                output.write(buffer, 0, read);
            }
            return target.getAbsolutePath();
        } catch (Exception e) {
            target.delete();
            return null;
        }
    }

    /**
     * Uses the same system UI flags as Flutter's PlatformPlugin, so "visible" restores exactly the
     * state Flutter sets up, and Flutter re-applying its own flags on resume is undone by
     * {@link #onWindowFocusChanged(boolean)}.
     */
    @SuppressWarnings("deprecation")
    private void applyNavigationBarState() {
        int flags = PlatformPlugin.DEFAULT_SYSTEM_UI;
        if (!"visible".equals(navigationBarMode)) {
            // Lay out behind the bar, so revealing it overlays the launcher instead of resizing it.
            flags |= View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
            if (!navigationBarRevealed) {
                // Sticky: a swipe from the bottom edge still shows the bar for a moment.
                flags |= View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
            }
        }
        getWindow().getDecorView().setSystemUiVisibility(flags);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus && !"visible".equals(navigationBarMode)) {
            navigationBarRevealed = false;
            applyNavigationBarState();
        }
    }

    private boolean applicationExists(String packageName) {
        int flags;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            flags = PackageManager.MATCH_UNINSTALLED_PACKAGES;
        } else {
            flags = PackageManager.GET_UNINSTALLED_PACKAGES;
        }

        try {
            getPackageManager().getApplicationInfo(packageName, flags);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private List<ResolveInfo> queryIntentActivities(boolean sideloaded) {
        String category;
        if (sideloaded) {
            category = Intent.CATEGORY_LAUNCHER;
        } else {
            category = Intent.CATEGORY_LEANBACK_LAUNCHER;
        }

        // NOTE: Would be nice to query the applications that match *either* of the
        // above categories
        // but from the addCategory function documentation, it says that it will "use
        // activities
        // that provide *all* the requested categories"
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .addCategory(category);

        return getPackageManager()
                .queryIntentActivities(intent, 0);
    }

    private Map<String, Serializable> buildAppMap(ActivityInfo activityInfo, boolean sideloaded, String action) {
        PackageManager packageManager = getPackageManager();

        String applicationName = activityInfo.loadLabel(packageManager).toString(),
                applicationVersionName = "";
        try {
            applicationVersionName = packageManager.getPackageInfo(activityInfo.packageName, 0).versionName;
        } catch (PackageManager.NameNotFoundException ignored) {
        }

        Map<String, Serializable> appMap = new HashMap<>();
        appMap.put("name", applicationName);
        appMap.put("packageName", activityInfo.packageName);
        appMap.put("version", applicationVersionName);
        appMap.put("sideloaded", sideloaded);

        if (action != null) {
            appMap.put("action", action);
        }
        return appMap;
    }

    private boolean launchActivityFromAction(String action) {
        return tryStartActivity(new Intent(action));
    }

    private boolean launchApp(String packageName) {
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        return tryStartActivity(intent);
    }

    private boolean openSettings() {
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean installApk(String apkPath) {
        File apkFile = new File(apkPath);
        if (!apkFile.exists()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !getPackageManager().canRequestPackageInstalls()) {
            return false;
        }

        Uri apkUri = FileProvider.getUriForFile(
                this,
                getPackageName() + ".fileprovider",
                apkFile
        );

        Intent installIntent = new Intent(Intent.ACTION_VIEW)
                .setDataAndType(apkUri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        return tryStartActivity(installIntent);
    }

    private void requestInstallUnknownAppsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                    .setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean openAppInfo(String packageName) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean uninstallApp(String packageName) {
        Intent intent = new Intent(Intent.ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean checkForGetContentAvailability() {
        List<ResolveInfo> intentActivities = getPackageManager().queryIntentActivities(
                new Intent(Intent.ACTION_GET_CONTENT, null).setTypeAndNormalize("image/*"),
                0);

        return !intentActivities.isEmpty();
    }

    private boolean isDefaultLauncher() {
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
        ResolveInfo defaultLauncher = getPackageManager().resolveActivity(intent, 0);

        if (defaultLauncher != null && defaultLauncher.activityInfo != null) {
            return defaultLauncher.activityInfo.packageName.equals(getPackageName());
        }

        return false;
    }

    private boolean startAmbientMode() {
        Intent intent = new Intent(Intent.ACTION_MAIN)
                .setClassName("com.android.systemui", "com.android.systemui.Somnambulator");

        return tryStartActivity(intent);
    }

    private Map<String, Object> getActiveNetworkInformation() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetwork());
        } else {
            // noinspection deprecation
            return NetworkUtils.getNetworkInformation(this, connectivityManager.getActiveNetworkInfo());
        }
    }

    private boolean tryStartActivity(Intent intent) {
        boolean success = true;

        try {
            startActivity(intent);
        } catch (Exception ignored) {
            success = false;
        }

        return success;
    }

    private byte[] drawableToByteArray(Drawable drawable) {
        if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) {
            return new byte[0];
        }

        Bitmap bitmap;
        if (drawable instanceof BitmapDrawable bitmapDrawable) {
            bitmap = bitmapDrawable.getBitmap();
        } else {
            bitmap = drawableToBitmap(drawable);
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        return stream.toByteArray();
    }

    Bitmap drawableToBitmap(Drawable drawable) {
        Bitmap bitmap = Bitmap.createBitmap(
                drawable.getIntrinsicWidth(),
                drawable.getIntrinsicHeight(),
                Bitmap.Config.ARGB_8888);

        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    private long getDailyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getWeeklyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_WEEK, calendar.getFirstDayOfWeek());
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private long getMonthlyWifiUsage() {
        if (!checkUsageStatsPermission()) {
            return -1;
        }

        NetworkStatsManager networkStatsManager = (NetworkStatsManager) getSystemService(Context.NETWORK_STATS_SERVICE);
        if (networkStatsManager == null)
            return 0;

        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.set(java.util.Calendar.DAY_OF_MONTH, 1);
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0);
        calendar.set(java.util.Calendar.MINUTE, 0);
        calendar.set(java.util.Calendar.SECOND, 0);
        calendar.set(java.util.Calendar.MILLISECOND, 0);
        long startTime = calendar.getTimeInMillis();
        long endTime = System.currentTimeMillis();

        long totalBytes = 0;
        try {
            NetworkStats.Bucket bucket = networkStatsManager.querySummaryForDevice(
                    NetworkCapabilities.TRANSPORT_WIFI,
                    "",
                    startTime,
                    endTime);
            totalBytes = bucket.getRxBytes() + bucket.getTxBytes();
        } catch (RemoteException e) {
            e.printStackTrace();
        }

        return totalBytes;
    }

    private boolean checkUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private void requestUsageStatsPermission() {
        Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
        tryStartActivity(intent);
    }

    private boolean checkWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.System.canWrite(this);
        }
        return true;
    }

    private void requestWriteSettingsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            tryStartActivity(intent);
        }
    }

    private boolean setSystemBrightness(int brightness) {
        if (checkWriteSettingsPermission()) {
            try {
                android.content.ContentResolver resolver = getContentResolver();
                // 1. Standard Android brightness
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS, brightness);
                
                // 2. Try common TV "Backlight" keys (Vendor specific)
                Settings.System.putInt(resolver, "backlight", brightness);
                Settings.System.putInt(resolver, "backlight_level", brightness);
                
                return true;
            } catch (Exception e) {
                // Ignore errors on specific keys as they may not exist
                return true;
            }
        }
        return false;
    }

    private boolean openWifiSettings() {
        // 1. Try Android Q+ WiFi panel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent panelIntent = new Intent(Settings.Panel.ACTION_WIFI);
            if (tryStartActivity(panelIntent)) {
                return true;
            }
        }

        // 2. Try standard WiFi settings
        Intent wifiIntent = new Intent(Settings.ACTION_WIFI_SETTINGS);
        if (tryStartActivity(wifiIntent)) {
            return true;
        }

        // 3. Fallback to general wireless settings
        Intent wirelessIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
        if (tryStartActivity(wirelessIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openScreensaverSettings() {
        // 1. Try Android TV specific screensaver settings (DaydreamActivity - from
        // Aerial Views)
        Intent tvIntent = new Intent(Intent.ACTION_MAIN);
        tvIntent.setClassName("com.android.tv.settings",
                "com.android.tv.settings.device.display.daydream.DaydreamActivity");
        if (tryStartActivity(tvIntent)) {
            return true;
        }

        // 2. Try standard Android screensaver/dream settings
        Intent dreamIntent = new Intent(Settings.ACTION_DREAM_SETTINGS);
        if (tryStartActivity(dreamIntent)) {
            return true;
        }

        // 3. FALLBACK: Try Display Settings (often contains screensaver on newer
        // Android TV/Google TV)
        Intent displayIntent = new Intent(Settings.ACTION_DISPLAY_SETTINGS);
        if (tryStartActivity(displayIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean checkWatchNextPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }
        return checkSelfPermission(PERMISSION_READ_TV_LISTINGS) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestWatchNextPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return;
        }
        if (checkWatchNextPermission()) {
            return;
        }
        ActivityCompat.requestPermissions(
                this,
                new String[]{PERMISSION_READ_TV_LISTINGS},
                REQUEST_CODE_READ_TV_LISTINGS);
    }

    private List<Map<String, Object>> getWatchNextItems(int limit) {
        List<Map<String, Object>> items = new ArrayList<>();

        if (!checkWatchNextPermission()) {
            android.util.Log.w("MainActivity", "READ_TV_LISTINGS permission not granted");
            return items;
        }

        try {
            String[] projection = {
                TvContract.WatchNextPrograms._ID,
                TvContract.WatchNextPrograms.COLUMN_TITLE,
                TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION,
                TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI,
                TvContract.WatchNextPrograms.COLUMN_THUMBNAIL_URI,
                TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME,
                TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
                TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS,
                TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
                TvContract.WatchNextPrograms.COLUMN_INTENT_URI,
                TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE
            };

            String sortOrder = TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS + " DESC";

            try (Cursor cursor = getContentResolver().query(
                    TvContract.WatchNextPrograms.CONTENT_URI,
                    projection,
                    null,
                    null,
                    sortOrder)) {

                if (cursor != null && cursor.moveToFirst()) {
                    int count = 0;
                    int fetchLimit = Math.max(limit * 3, 150);

                    do {
                        try {
                            Map<String, Object> item = new HashMap<>();

                            int idIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms._ID);
                            int titleIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_TITLE);
                            int descIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_SHORT_DESCRIPTION);
                            int posterIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_POSTER_ART_URI);
                            int thumbIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_THUMBNAIL_URI);
                            int pkgIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_PACKAGE_NAME);
                            int contentIdIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID);
                            int durationIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_DURATION_MILLIS);
                            int lastEngIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS);
                            int intentUriIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_INTENT_URI);
                            int watchTypeIndex = cursor.getColumnIndex(TvContract.WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE);
                            int aspectRatioIndex = cursor.getColumnIndex(COLUMN_ASPECT_RATIO);

                            String title = (titleIndex >= 0 && !cursor.isNull(titleIndex))
                                ? cursor.getString(titleIndex) : null;
                            if (title == null || title.isEmpty()) {
                                continue;
                            }

                            String posterUri = (posterIndex >= 0 && !cursor.isNull(posterIndex))
                                ? cursor.getString(posterIndex) : null;
                            if ((posterUri == null || posterUri.trim().isEmpty()) && thumbIndex >= 0 && !cursor.isNull(thumbIndex)) {
                                posterUri = cursor.getString(thumbIndex);
                            }

                            item.put("id", idIndex >= 0 ? cursor.getLong(idIndex) : 0);
                            item.put("title", title);
                            item.put("description", (descIndex >= 0 && !cursor.isNull(descIndex))
                                ? cursor.getString(descIndex) : null);
                            item.put("posterUri", posterUri);
                            item.put("packageName", (pkgIndex >= 0 && !cursor.isNull(pkgIndex))
                                ? cursor.getString(pkgIndex) : null);
                            item.put("contentId", (contentIdIndex >= 0 && !cursor.isNull(contentIdIndex))
                                ? cursor.getString(contentIdIndex) : null);
                            item.put("duration", (durationIndex >= 0 && !cursor.isNull(durationIndex))
                                ? cursor.getInt(durationIndex) : null);

                            item.put("intentUri", (intentUriIndex >= 0 && !cursor.isNull(intentUriIndex))
                                ? cursor.getString(intentUriIndex) : null);

                            item.put("watchNextType", (watchTypeIndex >= 0 && !cursor.isNull(watchTypeIndex))
                                ? cursor.getInt(watchTypeIndex) : 0);

                            item.put("aspectRatio", (aspectRatioIndex >= 0 && !cursor.isNull(aspectRatioIndex))
                                ? cursor.getString(aspectRatioIndex) : null);

                            if (lastEngIndex >= 0 && !cursor.isNull(lastEngIndex)) {
                                item.put("lastEngagementDate", cursor.getLong(lastEngIndex));
                            }

                            item.put("progressPercent", 0);

                            items.add(item);
                            count++;
                        } catch (Exception rowEx) {
                            android.util.Log.w("MainActivity", "Error parsing Watch Next row", rowEx);
                        }
                    } while (cursor.moveToNext() && count < fetchLimit);
                }
            }
        } catch (SecurityException e) {
            android.util.Log.w("MainActivity", "SecurityException when querying Watch Next: " + e.getMessage());
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error querying Watch Next", e);
        }

        android.util.Log.d("MainActivity", "getWatchNextItems: total retrieved = " + items.size() + ", limit = " + limit);
        return items.subList(0, Math.min(items.size(), limit));
    }

    private boolean launchWatchNextItem(String packageName, String contentId, String action) {
        android.util.Log.d("MainActivity", "launchWatchNextItem: packageName=" + packageName + ", contentId=" + contentId + ", action=" + action);

        // Try to use the intent action/uri from arguments first
        if (action != null && !action.isEmpty()) {
            try {
                Intent intent;
                if (action.startsWith("intent://")) {
                    android.util.Log.d("MainActivity", "Parsing intent URI: " + action);
                    intent = Intent.parseUri(action, Intent.URI_INTENT_SCHEME);
                } else if (action.startsWith("content://") || action.startsWith("http://") || action.startsWith("https://")) {
                    android.util.Log.d("MainActivity", "Creating VIEW intent for URI: " + action);
                    intent = new Intent(Intent.ACTION_VIEW, Uri.parse(action));
                } else if (action.contains(":")) {
                    try {
                        android.util.Log.d("MainActivity", "Trying to parse as intent URI: " + action);
                        intent = Intent.parseUri(action, Intent.URI_INTENT_SCHEME);
                    } catch (Exception e) {
                        android.util.Log.w("MainActivity", "Failed to parse as intent URI, treating as action: " + action);
                        intent = new Intent(action);
                    }
                } else {
                    android.util.Log.d("MainActivity", "Creating intent with action: " + action);
                    intent = new Intent(action);
                }

                if (packageName != null) {
                    intent.setPackage(packageName);
                    android.util.Log.d("MainActivity", "Set package to: " + packageName);
                }
                if (contentId != null) {
                    intent.putExtra("contentId", contentId);
                    android.util.Log.d("MainActivity", "Added contentId extra: " + contentId);
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                android.util.Log.d("MainActivity", "Starting activity with intent: " + intent.toUri(0));
                return tryStartActivity(intent);
            } catch (Exception e) {
                android.util.Log.e("MainActivity", "Failed to launch with action/uri: " + action, e);
            }
        }

        // Fallback to package name
        if (packageName == null) {
            android.util.Log.w("MainActivity", "No package name or action available, cannot launch");
            return false;
        }

        try {
            android.util.Log.d("MainActivity", "Falling back to package launch: " + packageName);
            PackageManager pm = getPackageManager();
            Intent intent = pm.getLeanbackLaunchIntentForPackage(packageName);
            if (intent == null) {
                intent = pm.getLaunchIntentForPackage(packageName);
            }

            if (intent != null) {
                if (contentId != null) {
                    intent.putExtra("contentId", contentId);
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                return tryStartActivity(intent);
            } else {
                android.util.Log.w("MainActivity", "No launch intent found for package: " + packageName);
            }
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error launching Watch Next item for package: " + packageName, e);
        }

        return false;
    }

    /**
     * Load image bytes from a content:// URI
     */
    private byte[] loadContentUriImage(String contentUri) {
        android.util.Log.d("MainActivity", "Loading content URI image: " + contentUri);
        try {
            android.net.Uri uri = android.net.Uri.parse(contentUri);
            android.util.Log.d("MainActivity", "Parsed URI: " + uri);

            try (java.io.InputStream inputStream = getContentResolver().openInputStream(uri)) {
                if (inputStream != null) {
                    java.io.ByteArrayOutputStream byteArrayOutputStream = new java.io.ByteArrayOutputStream();
                    byte[] buffer = new byte[8192];  // Increased buffer size
                    int length;
                    while ((length = inputStream.read(buffer)) != -1) {
                        byteArrayOutputStream.write(buffer, 0, length);
                    }
                    byte[] result = byteArrayOutputStream.toByteArray();
                    android.util.Log.d("MainActivity", "Loaded " + result.length + " bytes from content URI");
                    return result;
                } else {
                    android.util.Log.w("MainActivity", "openInputStream returned null for: " + contentUri);
                }
            }
        } catch (SecurityException e) {
            android.util.Log.w("MainActivity", "SecurityException loading content URI: " + e.getMessage());
        } catch (Exception e) {
            android.util.Log.e("MainActivity", "Error loading content URI image: " + contentUri, e);
        }
        android.util.Log.w("MainActivity", "Returning empty byte array for: " + contentUri);
        return new byte[0];
    }

    private static final int MEDIA_PERMISSION_REQUEST_CODE = 9001;

    private boolean checkMediaPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return checkSelfPermission(Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
                && checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED;
        }
        return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestMediaPermissions() {
        String[] permissions;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions = new String[]{
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            };
        } else {
            permissions = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE};
        }
        ActivityCompat.requestPermissions(this, permissions, MEDIA_PERMISSION_REQUEST_CODE);
    }

    private List<Map<String, Object>> getMediaStoreImages() {
        List<Map<String, Object>> images = new ArrayList<>();
        String[] projection = {
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED
        };
        String sortOrder = MediaStore.Images.Media.DATE_ADDED + " DESC";

        try (Cursor cursor = getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection, null, null, sortOrder)) {
            if (cursor != null) {
                int idCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
                int nameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME);
                int dataCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
                while (cursor.moveToNext()) {
                    long id = cursor.getLong(idCol);
                    Uri contentUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", id);
                    item.put("name", cursor.getString(nameCol));
                    item.put("path", cursor.getString(dataCol));
                    item.put("uri", contentUri.toString());
                    images.add(item);
                }
            }
        } catch (Exception ignored) {
        }
        return images;
    }

    private List<Map<String, Object>> getMediaStoreVideos() {
        List<Map<String, Object>> videos = new ArrayList<>();
        String[] projection = {
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_ADDED
        };
        String sortOrder = MediaStore.Video.Media.DATE_ADDED + " DESC";

        try (Cursor cursor = getContentResolver().query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection, null, null, sortOrder)) {
            if (cursor != null) {
                int idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID);
                int nameCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME);
                int dataCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA);
                while (cursor.moveToNext()) {
                    long id = cursor.getLong(idCol);
                    Uri contentUri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, String.valueOf(id));
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", id);
                    item.put("name", cursor.getString(nameCol));
                    item.put("path", cursor.getString(dataCol));
                    item.put("uri", contentUri.toString());
                    videos.add(item);
                }
            }
        } catch (Exception ignored) {
        }
        return videos;
    }

    private byte[] getMediaStoreVideoThumbnail(long id, String path) {
        Bitmap bitmap = null;
        try {
            if (id >= 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                Uri uri = android.content.ContentUris.withAppendedId(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id);
                bitmap = getContentResolver().loadThumbnail(
                    uri, new android.util.Size(256, 256), null);
            }
        } catch (Exception ignored) {
        }

        if (bitmap == null && path != null && !path.isEmpty()) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    bitmap = android.media.ThumbnailUtils.createVideoThumbnail(
                        new File(path), new android.util.Size(256, 256), null);
                } else {
                    bitmap = android.media.ThumbnailUtils.createVideoThumbnail(
                        path, MediaStore.Images.Thumbnails.MINI_KIND);
                }
            } catch (Exception ignored) {
            }
        }

        if (bitmap == null && path != null && !path.isEmpty()) {
            android.media.MediaMetadataRetriever retriever = null;
            try {
                retriever = new android.media.MediaMetadataRetriever();
                retriever.setDataSource(path);
                bitmap = retriever.getFrameAtTime(0);
            } catch (Exception ignored) {
            } finally {
                try {
                    if (retriever != null) retriever.release();
                } catch (Exception ignored) {
                }
            }
        }

        if (bitmap == null) return null;
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream);
        bitmap.recycle();
        return stream.toByteArray();
    }

}
