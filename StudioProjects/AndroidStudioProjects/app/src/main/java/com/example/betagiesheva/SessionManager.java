package com.example.betagiesheva;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * SessionManager — stores user session info + JWT auth token.
 *
 * Critical: the JWT token MUST be saved at login/registration, otherwise
 * every add/update/delete API call will fail with HTTP 401 (the server's
 * authUser() helper requires `Authorization: Bearer <token>`).
 */
public class SessionManager {

    private SharedPreferences pref;
    private SharedPreferences.Editor editor;

    public SessionManager(Context context) {
        pref = context.getSharedPreferences(Config.PREF_NAME, Context.MODE_PRIVATE);
        editor = pref.edit();
    }

    /** Save full user info including user_type AND JWT token. */
    public void saveUser(String id, String name, String phone,
                         String address, String union, String imageUrl,
                         String userType, String token) {
        editor.putBoolean("isLogin", true);
        editor.putString("id", id);
        editor.putString("name", name);
        editor.putString("phone", phone);
        editor.putString("address", address);
        editor.putString("union", union);
        editor.putString("imageUrl", imageUrl);
        editor.putString("userType", userType); // admin / user
        editor.putString("token", token);       // JWT for Authorization header
        editor.apply();
    }

    /** Backward-compat overload (no token) — kept for any legacy callers. */
    public void saveUser(String id, String name, String phone,
                         String address, String union, String imageUrl, String userType) {
        saveUser(id, name, phone, address, union, imageUrl, userType, "");
    }

    public boolean isLogin() {
        return pref.getBoolean("isLogin", false);
    }

    public void logout() {
        editor.clear();
        editor.apply();
    }

    // ── JWT token ─────────────────────────────────────────
    public void saveToken(String token) {
        editor.putString("token", token);
        editor.apply();
    }

    /** Returns the JWT token, or empty string if not set. */
    public String getToken() {
        return pref.getString("token", "");
    }

    public boolean hasToken() {
        String t = getToken();
        return t != null && !t.isEmpty();
    }

    // ── Getters ───────────────────────────────────────────
    public String getId()        { return pref.getString("id", ""); }
    public String getName()      { return pref.getString("name", ""); }
    public String getPhone()     { return pref.getString("phone", ""); }
    public String getAddress()   { return pref.getString("address", ""); }
    public String getUnion()     { return pref.getString("union", ""); }
    public String getImageUrl()  { return pref.getString("imageUrl", ""); }
    public String getUserType()  { return pref.getString("userType", "user"); }

    /** Convenience: is the logged-in user an admin? */
    public boolean isAdmin() {
        return "admin".equalsIgnoreCase(getUserType());
    }
}
