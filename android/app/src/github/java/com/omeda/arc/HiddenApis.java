package com.omeda.arc;

import android.os.Build;

import org.lsposed.hiddenapibypass.HiddenApiBypass;

/** Opens Android's non-SDK interfaces to reflection. Only the GitHub build does; the Play build has its own copy. */
final class HiddenApis {
    private HiddenApis() {
    }

    /** Whether members of the classes whose descriptors start with {@code prefixes} can now be reached by reflection. */
    static boolean exempt(String... prefixes) {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.P || HiddenApiBypass.addHiddenApiExemptions(prefixes);
    }
}
