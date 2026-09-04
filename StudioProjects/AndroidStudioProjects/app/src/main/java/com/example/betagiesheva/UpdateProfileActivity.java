package com.example.betagiesheva;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.helper.AuthRequest;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class UpdateProfileActivity extends AppCompatActivity {

    private static final String TAG = "UpdateProfileActivity";

    // UI Components
    private CircleImageView profileImageView;
    private EditText nameInput, phoneInput, addressInput;
    private CardView submitButton;
    private ProgressBar progressBar;
    private ImageView cameraIcon;

    // Data – use SessionManager (same as LoginActivity)
    private SessionManager sessionManager;
    private String userId;
    private String profileImageBase64 = "";
    private Bitmap selectedBitmap = null;

    // Image Picker
    private final ActivityResultLauncher<String> imagePickerLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.GetContent(),
                    uri -> {
                        if (uri != null) {
                            try {
                                selectedBitmap = MediaStore.Images.Media.getBitmap(
                                        getContentResolver(), uri
                                );
                                profileImageView.setImageBitmap(selectedBitmap);
                                profileImageBase64 = bitmapToBase64(selectedBitmap);
                            } catch (IOException e) {
                                e.printStackTrace();
                                Toast.makeText(this, "ছবি লোড করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                            }
                        }
                    }
            );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_update_profile);

        sessionManager = new SessionManager(this);
        if (!sessionManager.isLogin()) {
            startActivity(new Intent(this, LoginActivity.class));
            finish();
            return;
        }
        userId = sessionManager.getId();
        if (TextUtils.isEmpty(userId)) {
            Toast.makeText(this, "সেশন পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("প্রোফাইল আপডেট করুন");
        }

        initViews();
        setupClickListeners();
        loadProfileFromSession();
        fetchProfileFromServer();
    }

    private void initViews() {
        profileImageView = findViewById(R.id.profileImage);
        nameInput = findViewById(R.id.nameInput);
        phoneInput = findViewById(R.id.phoneInput);
        addressInput = findViewById(R.id.addressInput);
        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);
        cameraIcon = findViewById(R.id.cameraIcon);
    }

    private void setupClickListeners() {
        profileImageView.setOnClickListener(v -> imagePickerLauncher.launch("image/*"));
        cameraIcon.setOnClickListener(v -> imagePickerLauncher.launch("image/*"));
        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                updateProfile();
            }
        });
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }

    /** Pre-fill form from SessionManager (same data saved at login). */
    private void loadProfileFromSession() {
        nameInput.setText(sessionManager.getName());
        phoneInput.setText(sessionManager.getPhone());
        addressInput.setText(sessionManager.getAddress());

        String imageUrl = sessionManager.getImageUrl();
        if (!TextUtils.isEmpty(imageUrl) && !"default.png".equalsIgnoreCase(imageUrl)) {
            Glide.with(this)
                    .load(Config.IMAGE_URL + imageUrl)
                    .placeholder(R.drawable.profile)
                    .error(R.drawable.profile)
                    .into(profileImageView);
        } else {
            profileImageView.setImageResource(R.drawable.profile);
        }
    }

    /** Optionally refresh from server and override form. */
    private void fetchProfileFromServer() {
        // CRITICAL FIX: profile.php now requires JWT — use AuthRequest
        com.example.betagiesheva.helper.AuthRequest request = new com.example.betagiesheva.helper.AuthRequest(
                Request.Method.POST,
                Config.PROFILE_URL,
                response -> {
                    try {
                        JSONObject json = new JSONObject(response);
                        if (!"success".equals(json.optString("status"))) return;

                        JSONObject data = json.getJSONObject("data");
                        nameInput.setText(data.optString("name", sessionManager.getName()));
                        phoneInput.setText(data.optString("phone", sessionManager.getPhone()));
                        addressInput.setText(data.optString("address", sessionManager.getAddress()));

                        String image = data.optString("image", "");
                        if (!TextUtils.isEmpty(image)) {
                            Glide.with(UpdateProfileActivity.this)
                                    .load(image)
                                    .placeholder(R.drawable.profile)
                                    .error(R.drawable.profile)
                                    .into(profileImageView);
                        }
                    } catch (JSONException e) {
                        // Keep session data on parse error
                    }
                },
                error -> { /* keep session data */ },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> map = new HashMap<>();
                map.put("user_id", userId);
                return map;
            }
        };

        Config.getInstance(this).addToRequestQueue(request);
    }

    private boolean validateForm() {
        String name = nameInput.getText().toString().trim();
        String phone = phoneInput.getText().toString().trim();
        String address = addressInput.getText().toString().trim();

        if (name.isEmpty()) {
            nameInput.setError("নাম প্রয়োজন");
            nameInput.requestFocus();
            return false;
        }

        return true;
    }

    private void updateProfile() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        String name = nameInput.getText().toString().trim();
        String phone = phoneInput.getText().toString().trim();
        String address = addressInput.getText().toString().trim();

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.UPDATE_PROFILE_URL,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success", false)) {
                            // Update session so ProfileFragment and app stay in sync (matching LoginActivity)
                            String newName = nameInput.getText().toString().trim();
                            String newPhone = phoneInput.getText().toString().trim();
                            String newAddress = addressInput.getText().toString().trim();
                            String newImage = json.optString("image", sessionManager.getImageUrl());
                            if (TextUtils.isEmpty(newImage)) newImage = sessionManager.getImageUrl();

                            sessionManager.saveUser(
                                    userId,
                                    newName,
                                    newPhone,
                                    newAddress,
                                    sessionManager.getUnion(),
                                    newImage,
                                    sessionManager.getUserType()
                            );

                            Toast.makeText(UpdateProfileActivity.this,
                                    "প্রোফাইল সফলভাবে আপডেট হয়েছে",
                                    Toast.LENGTH_SHORT).show();
                            finish();
                        } else {
                            String message = json.optString("message", "আপডেট ব্যর্থ");
                            Toast.makeText(UpdateProfileActivity.this, message, Toast.LENGTH_LONG).show();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(UpdateProfileActivity.this, "রেসপন্স পার্স এরর", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    error.printStackTrace();

                    String errorMsg = "নেটওয়ার্ক সমস্যা";
                    if (error.networkResponse != null) {
                        errorMsg += " (Code: " + error.networkResponse.statusCode + ")";
                        Log.e(TAG, "Error response: " + new String(error.networkResponse.data));
                    }

                    Toast.makeText(UpdateProfileActivity.this, errorMsg, Toast.LENGTH_LONG).show();
                    Log.e(TAG, "Network error: " + error.getMessage());
                },
                this
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
                Map<String, String> headers = super.getHeaders();
                headers.put("Accept-Charset", "UTF-8");
                headers.put("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                return headers;
            }

            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                params.put("user_id", userId);
                params.put("name", name);
                params.put("phone", phone);
                params.put("address", address);

                if (!TextUtils.isEmpty(profileImageBase64)) {
                    params.put("image", profileImageBase64);
                }

                return params;
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void hideKeyboard() {
        View view = getCurrentFocus();
        if (view != null) {
            InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
            }
        }
    }
}