package com.example.betagiesheva.Fragment;

import android.app.Dialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.AppsDetailsActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.LoginActivity;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.example.betagiesheva.UpdateProfileActivity;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class ProfileFragment extends Fragment {

    private static final String TAG = "ProfileFragment";

    private CircleImageView profileImg;
    private TextView nameText;
    private TextView phoneText;
    private TextView unionText;

    private View profileUpdate, passUpdate, adsUpdate,
            fbPage, fbGroup, appDetails, developer, logout;

    private SessionManager sessionManager;

    @Nullable
    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState
    ) {
        View view = inflater.inflate(R.layout.fragment_profile, container, false);

        sessionManager = new SessionManager(requireContext());

        if (!sessionManager.isLogin()) {
            startActivity(new Intent(requireContext(), LoginActivity.class));
            requireActivity().finish();
            return view;
        }

        initViews(view);
        loadProfileFromSession();
        fetchProfileFromServer();
        setupClicks();

        return view;
    }

    private void initViews(View view) {
        profileImg = view.findViewById(R.id.profileimg);
        nameText = view.findViewById(R.id.name);
        phoneText = view.findViewById(R.id.profile_phone);
        unionText = view.findViewById(R.id.profile_union);

        profileUpdate = view.findViewById(R.id.profileupdate);
        passUpdate = view.findViewById(R.id.passUpdate);
        adsUpdate = view.findViewById(R.id.adsUpdate);
        fbPage = view.findViewById(R.id.fbpage);
        fbGroup = view.findViewById(R.id.fbgroup);
        appDetails = view.findViewById(R.id.appdel);
        developer = view.findViewById(R.id.developer);
        logout = view.findViewById(R.id.logout);
    }

    /** Show name, phone, union and image from SessionManager (saved at login). */
    private void loadProfileFromSession() {
        nameText.setText(TextUtils.isEmpty(sessionManager.getName()) ? getString(R.string.app_name) : sessionManager.getName());
        if (phoneText != null) {
            phoneText.setText(TextUtils.isEmpty(sessionManager.getPhone()) ? "" : sessionManager.getPhone());
            phoneText.setVisibility(TextUtils.isEmpty(sessionManager.getPhone()) ? View.GONE : View.VISIBLE);
        }
        if (unionText != null) {
            unionText.setText(TextUtils.isEmpty(sessionManager.getUnion()) ? "" : sessionManager.getUnion());
            unionText.setVisibility(TextUtils.isEmpty(sessionManager.getUnion()) ? View.GONE : View.VISIBLE);
        }

        String imageUrl = sessionManager.getImageUrl();
        if (!TextUtils.isEmpty(imageUrl) && !"default.png".equalsIgnoreCase(imageUrl)) {
            Glide.with(this)
                    .load(Config.IMAGE_URL + imageUrl)
                    .placeholder(R.drawable.profile)
                    .error(R.drawable.profile)
                    .into(profileImg);
        } else {
            profileImg.setImageResource(R.drawable.profile);
        }
    }

    /** Optionally refresh profile from server; updates UI if success. */
    private void fetchProfileFromServer() {
        String userId = sessionManager.getId();
        if (TextUtils.isEmpty(userId)) return;

        // CRITICAL FIX: profile.php now requires JWT — use AuthRequest
        com.example.betagiesheva.helper.AuthRequest request = new com.example.betagiesheva.helper.AuthRequest(
                Request.Method.POST,
                Config.PROFILE_URL,
                response -> {
                    try {
                        JSONObject json = new JSONObject(response);
                        if (!"success".equals(json.optString("status"))) return;

                        JSONObject data = json.getJSONObject("data");
                        nameText.setText(data.optString("name", sessionManager.getName()));

                        // BUG FIX: profile.php returns the image as a bare filename
                        // (basename only — same convention as login.php/register.php),
                        // NOT a full URL. Must prepend Config.IMAGE_URL, same as
                        // loadProfileFromSession() already does below.
                        String image = data.optString("image", "");
                        if (!TextUtils.isEmpty(image) && !"default.png".equalsIgnoreCase(image)) {
                            Glide.with(this)
                                    .load(Config.IMAGE_URL + image)
                                    .placeholder(R.drawable.profile)
                                    .error(R.drawable.profile)
                                    .into(profileImg);
                        }
                    } catch (Exception e) {
                        // Keep session data on parse error
                    }
                },
                error -> Log.e(TAG, "Profile refresh failed, keeping cached session data: " + error.getMessage()),
                requireContext()
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> map = new HashMap<>();
                map.put("user_id", userId);
                return map;
            }
        };

        Config.getInstance(requireContext()).addToRequestQueue(request);
    }

    private void setupClicks() {
        profileUpdate.setOnClickListener(v ->
                startActivity(new Intent(requireContext(), UpdateProfileActivity.class))
        );

        passUpdate.setOnClickListener(v -> showChangePasswordDialog());

        adsUpdate.setOnClickListener(v ->
                openUrl("https://wa.me/8801711000000")
        );

        fbPage.setOnClickListener(v ->
                openUrl("https://facebook.com/betagi.esheva")
        );

        fbGroup.setOnClickListener(v ->
                openUrl("https://facebook.com/betagi.esheva")
        );

        appDetails.setOnClickListener(v ->
                startActivity(new Intent(requireContext(), AppsDetailsActivity.class))
        );

        // Phase 3: Developer info — displays Md. Abdullah Al Hossain (App Developer)
        if (developer != null) {
            developer.setOnClickListener(v -> showDeveloperInfoDialog());
        }

        logout.setOnClickListener(v -> logoutUser());
    }

    private void logoutUser() {
        sessionManager.logout();
        toast("লগ আউট সফল");
        startActivity(new Intent(requireContext(), LoginActivity.class));
        requireActivity().finish();
    }

    /**
     * Phase 3 — Developer info dialog.
     * Displays the app developer's name (Md. Abdullah Al Hossain), role, and contact info.
     * Reads from R.string.about_developer (defined in strings.xml) so the text is editable
     * without code changes.
     */
    private void showDeveloperInfoDialog() {
        Dialog dialog = new Dialog(requireContext());
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.dialog_developer_info);
        dialog.setCancelable(true);

        TextView titleView = dialog.findViewById(R.id.developerTitle);
        TextView bodyView  = dialog.findViewById(R.id.developerBody);
        CardView closeButton = dialog.findViewById(R.id.developerCloseButton);

        if (titleView != null) {
            titleView.setText("ডেভেলপার সম্পর্কে");
        }
        if (bodyView != null) {
            bodyView.setText(getString(R.string.about_developer));
        }
        if (closeButton != null) {
            closeButton.setOnClickListener(v -> dialog.dismiss());
        }

        dialog.show();
    }

    private void openUrl(String url) {
        startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
    }

    private void toast(String msg) {
        Toast.makeText(getContext(), msg, Toast.LENGTH_SHORT).show();
    }

    /** Show password change dialog instead of opening Activity. */
    private void showChangePasswordDialog() {
        Dialog dialog = new Dialog(requireContext());
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.dialog_change_password);
        dialog.setCancelable(true);

        TextInputEditText oldPasswordInput = dialog.findViewById(R.id.dialogOldPasswordInput);
        TextInputEditText newPasswordInput = dialog.findViewById(R.id.dialogNewPasswordInput);
        TextInputEditText confirmPasswordInput = dialog.findViewById(R.id.dialogConfirmPasswordInput);
        CardView submitButton = dialog.findViewById(R.id.dialogSubmitButton);
        CardView cancelButton = dialog.findViewById(R.id.dialogCancelButton);
        ProgressBar progressBar = dialog.findViewById(R.id.dialogProgress);

        cancelButton.setOnClickListener(v -> dialog.dismiss());

        submitButton.setOnClickListener(v -> {
            if (validatePasswordForm(oldPasswordInput, newPasswordInput, confirmPasswordInput)) {
                changePassword(oldPasswordInput, newPasswordInput, confirmPasswordInput, progressBar, submitButton, cancelButton, dialog);
            }
        });

        dialog.show();
    }

    private boolean validatePasswordForm(TextInputEditText oldPasswordInput,
                                         TextInputEditText newPasswordInput,
                                         TextInputEditText confirmPasswordInput) {
        String oldPassword = oldPasswordInput.getText().toString().trim();
        String newPassword = newPasswordInput.getText().toString().trim();
        String confirmPassword = confirmPasswordInput.getText().toString().trim();

        if (oldPassword.isEmpty()) {
            oldPasswordInput.setError("বর্তমান পাসওয়ার্ড প্রয়োজন");
            oldPasswordInput.requestFocus();
            return false;
        }

        if (newPassword.isEmpty()) {
            newPasswordInput.setError("নতুন পাসওয়ার্ড প্রয়োজন");
            newPasswordInput.requestFocus();
            return false;
        }

        if (newPassword.length() < 6) {
            newPasswordInput.setError("পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে");
            newPasswordInput.requestFocus();
            return false;
        }

        if (!newPassword.equals(confirmPassword)) {
            confirmPasswordInput.setError("পাসওয়ার্ড মিলছে না");
            confirmPasswordInput.requestFocus();
            return false;
        }

        if (oldPassword.equals(newPassword)) {
            newPasswordInput.setError("নতুন পাসওয়ার্ড আগেরটির মতো হতে পারে না");
            newPasswordInput.requestFocus();
            return false;
        }

        return true;
    }

    private void changePassword(TextInputEditText oldPasswordInput,
                                TextInputEditText newPasswordInput,
                                TextInputEditText confirmPasswordInput,
                                ProgressBar progressBar,
                                CardView submitButton,
                                CardView cancelButton,
                                Dialog dialog) {
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);
        cancelButton.setEnabled(false);

        String userId = sessionManager.getId();
        String oldPassword = oldPasswordInput.getText().toString().trim();
        String newPassword = newPasswordInput.getText().toString().trim();
        String confirmPassword = confirmPasswordInput.getText().toString().trim();

        StringRequest request = new StringRequest(
                Request.Method.POST,
                Config.CHANGE_PASSWORD_URL,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    cancelButton.setEnabled(true);

                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success", false)) {
                            toast("পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে");
                            dialog.dismiss();
                        } else {
                            String message = json.optString("message", "পাসওয়ার্ড পরিবর্তন ব্যর্থ");
                            toast(message);
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        toast("রেসপন্স পার্স এরর");
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    cancelButton.setEnabled(true);

                    // update_password.php uses sendError() for validation failures
                    // (wrong old password / mismatch / weak password / rate-limited),
                    // which returns HTTP 400/429 — Volley routes those HERE, not to
                    // the success listener above. Must parse the body to show the
                    // real message (e.g. "পুরনো পাসওয়ার্ড ভুল") instead of a generic one.
                    String errorMessage = "নেটওয়ার্ক সমস্যা, আবার চেষ্টা করুন";
                    if (error.networkResponse != null && error.networkResponse.data != null) {
                        try {
                            String body = new String(error.networkResponse.data, "UTF-8");
                            Log.e(TAG, "Password change error | Status: " + error.networkResponse.statusCode + " | Body: " + body);
                            JSONObject errJson = new JSONObject(body);
                            if (errJson.has("message")) {
                                errorMessage = errJson.getString("message");
                            }
                        } catch (JSONException | UnsupportedEncodingException e) {
                            Log.e(TAG, "Error parsing password-change error body: " + e.getMessage());
                        }
                    } else {
                        Log.e(TAG, "Password change error without network response: " + error.getMessage());
                    }

                    toast(errorMessage);
                }
        ) {
            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String utf8String = new String(response.data, "UTF-8");
                    return Response.success(utf8String,
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response));
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }

            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                Map<String, String> headers = new HashMap<>();
                headers.put("Accept-Charset", "UTF-8");
                headers.put("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                // CRITICAL FIX: Server now requires JWT for password change
                String token = sessionManager.getToken();
                if (token != null && !token.isEmpty()) {
                    headers.put("Authorization", "Bearer " + token);
                }
                return headers;
            }

            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                // user_id is no longer needed (server uses JWT), but send for backward compat
                params.put("old_password", oldPassword);
                params.put("new_password", newPassword);
                params.put("confirm_password", confirmPassword);
                return params;
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(requireContext()).addToRequestQueue(request);
    }
}