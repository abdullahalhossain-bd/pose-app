package com.example.betagiesheva.helper;

import android.content.Context;
import android.content.SharedPreferences;

public class SharedPreferencesHelper {
    private static final String PREF_NAME = "BusinessTypePref";
    private static final String KEY_BUSINESS_TYPE = "business_type";
    private static final String KEY_DISPLAY_NAME = "display_name";

    // User authentication preferences
    private static final String USER_PREF_NAME = "MyAppPrefs";
    private static final String KEY_USER_ID = "user_id";
    private static final String KEY_USER_NAME = "user_name";
    private static final String KEY_USER_PHONE = "user_phone";
    private static final String KEY_USER_ADDRESS = "user_address";
    private static final String KEY_USER_UNION = "user_union";
    private static final String KEY_USER_IMAGE_URL = "user_image_url";
    private static final String KEY_USER_ROLE = "user_role";
    private static final String KEY_IS_LOGGED_IN = "isLoggedIn";
    private static final String KEY_IS_REGISTERED = "isRegistered";

    private SharedPreferences businessPrefs;
    private SharedPreferences userPrefs;
    private SharedPreferences.Editor businessEditor;
    private SharedPreferences.Editor userEditor;

    public SharedPreferencesHelper(Context context) {
        businessPrefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        userPrefs = context.getSharedPreferences(USER_PREF_NAME, Context.MODE_PRIVATE);
        businessEditor = businessPrefs.edit();
        userEditor = userPrefs.edit();
    }

    // ==================== Business Type Methods ====================

    // Save business type and display name
    public void saveBusinessType(String businessType, String displayName) {
        businessEditor.putString(KEY_BUSINESS_TYPE, businessType);
        businessEditor.putString(KEY_DISPLAY_NAME, displayName);
        businessEditor.apply();
    }

    // Get business type
    public String getBusinessType() {
        return businessPrefs.getString(KEY_BUSINESS_TYPE, "");
    }

    // Get display name
    public String getDisplayName() {
        return businessPrefs.getString(KEY_DISPLAY_NAME, "");
    }

    // Clear saved business type data
    public void clearBusinessType() {
        businessEditor.remove(KEY_BUSINESS_TYPE);
        businessEditor.remove(KEY_DISPLAY_NAME);
        businessEditor.apply();
    }

    // ==================== User Authentication Methods ====================

    // Save user ID
    public void saveUserId(String userId) {
        userEditor.putString(KEY_USER_ID, userId);
        userEditor.apply();
    }

    // Get user ID
    public String getUserId() {
        return userPrefs.getString(KEY_USER_ID, "");
    }

    // Save complete user data
    public void saveUserData(String userId, String userName, String userPhone,
                             String userAddress, String userUnion, String userImageUrl, String userRole) {
        userEditor.putString(KEY_USER_ID, userId);
        userEditor.putString(KEY_USER_NAME, userName);
        userEditor.putString(KEY_USER_PHONE, userPhone);
        userEditor.putString(KEY_USER_ADDRESS, userAddress);
        userEditor.putString(KEY_USER_UNION, userUnion);
        userEditor.putString(KEY_USER_IMAGE_URL, userImageUrl);
        userEditor.putString(KEY_USER_ROLE, userRole);
        userEditor.putBoolean(KEY_IS_LOGGED_IN, true);
        userEditor.putBoolean(KEY_IS_REGISTERED, true);
        userEditor.apply();
    }

    // Get user name
    public String getUserName() {
        return userPrefs.getString(KEY_USER_NAME, "");
    }

    // Get user phone
    public String getUserPhone() {
        return userPrefs.getString(KEY_USER_PHONE, "");
    }

    // Get user address
    public String getUserAddress() {
        return userPrefs.getString(KEY_USER_ADDRESS, "");
    }

    // Get user union
    public String getUserUnion() {
        return userPrefs.getString(KEY_USER_UNION, "");
    }

    // Get user image URL
    public String getUserImageUrl() {
        return userPrefs.getString(KEY_USER_IMAGE_URL, "");
    }

    // Get user role
    public String getUserRole() {
        return userPrefs.getString(KEY_USER_ROLE, "");
    }

    // Check if user is logged in
    public boolean isLoggedIn() {
        return userPrefs.getBoolean(KEY_IS_LOGGED_IN, false);
    }

    // Check if user is registered
    public boolean isRegistered() {
        return userPrefs.getBoolean(KEY_IS_REGISTERED, false);
    }

    // Set login status
    public void setLoggedIn(boolean isLoggedIn) {
        userEditor.putBoolean(KEY_IS_LOGGED_IN, isLoggedIn);
        userEditor.apply();
    }

    // Clear all user data (logout)
    public void clearUserData() {
        userEditor.clear();
        userEditor.apply();
    }

    // Clear all data (both business and user)
    public void clearAllData() {
        businessEditor.clear();
        userEditor.clear();
        businessEditor.apply();
        userEditor.apply();
    }
}