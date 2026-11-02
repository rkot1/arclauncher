package com.omeda.arc;

import android.os.Build;

/** Google Play rejects apps that bypass the limits on Android's non-SDK interfaces, so this build does not. */
final class HiddenApis {
    private HiddenApis() {
    }

    /** Whether members of the classes whose descriptors start with {@code prefixes} can be reached by reflection. */
    static boolean exempt(String... prefixes) {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.P;
    }
}
