package com.example.betagiesheva.helper;

import android.text.TextUtils;

import com.example.betagiesheva.Config;

/**
 * ImageUtil — centralizes image URL handling.
 *
 * Server return shape is inconsistent across endpoints:
 *  - login.php / register.php: returns just the filename (basename), e.g. "img_abc.jpg"
 *  - All list/detail endpoints (donors, clinics, doctors, notices, etc.): returns
 *    the FULL URL via the server's imageUrl() helper, e.g.
 *    "https://nagoriksheba.com/betagi_backend/uploads/donors/img_abc.jpg"
 *
 * This helper detects which shape we got and returns a usable URL for Glide.
 */
public final class ImageUtil {

    private ImageUtil() { /* no instances */ }

    /**
     * Resolve a server-returned image string to a loadable URL.
     *
     *  - If null/empty/"default.png" → returns empty (caller should use placeholder drawable)
     *  - If already a full URL (starts with "http") → returned as-is
     *  - If a bare filename → prepended with Config.IMAGE_URL (profiles/ folder)
     *    (this case is only correct for user profile images from login/register)
     */
    public static String resolve(String image) {
        if (TextUtils.isEmpty(image) || "default.png".equalsIgnoreCase(image)) {
            return "";
        }
        if (image.startsWith("http://") || image.startsWith("https://")) {
            return image;
        }
        // Bare filename — assume profile image (only login/register return this shape)
        return Config.IMAGE_URL + image;
    }

    /** True if the resolved URL is non-empty and loadable. */
    public static boolean isLoadable(String url) {
        return !TextUtils.isEmpty(url);
    }
}
