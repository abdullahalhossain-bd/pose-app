package com.example.betagiesheva;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

public class ChangePasswordActivity extends AppCompatActivity {

    private static final String TAG = "ChangePasswordActivity";

    // UI Components
    private TextInputEditText oldPasswordInput, newPasswordInput, confirmPasswordInput;
    private CardView submitButton;
    private ProgressBar progressBar;

    // Data – use SessionManager (same as LoginActivity)
    private SessionManager sessionManager;
    private String userId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_password);

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
            getSupportActionBar().setTitle("পাসওয়ার্ড পরিবর্তন করুন");
        }

        initViews();
        setupClickListeners();
    }

    private void initViews() {
        oldPasswordInput = findViewById(R.id.oldPasswordInput);
        newPasswordInput = findViewById(R.id.newPasswordInput);
        confirmPasswordInput = findViewById(R.id.confirmPasswordInput);
        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);
    }

    private void setupClickListeners() {
        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                changePassword();
            }
        });
    }

    private boolean validateForm() {
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

    private void changePassword() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        String oldPassword = oldPasswordInput.getText().toString().trim();
        String newPassword = newPasswordInput.getText().toString().trim();
        String confirmPassword = confirmPasswordInput.getText().toString().trim();

        StringRequest request = new StringRequest(
                Request.Method.POST,
                Config.CHANGE_PASSWORD_URL,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    Log.d(TAG, "Response: " + response);

                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success", false)) {
                            Toast.makeText(ChangePasswordActivity.this,
                                    "পাসওয়ার্ড সফলভাবে পরিবর্তন করা হয়েছে",
                                    Toast.LENGTH_SHORT).show();
                            finish();
                        } else {
                            String message = json.optString("message", "পাসওয়ার্ড পরিবর্তন ব্যর্থ");
                            Toast.makeText(ChangePasswordActivity.this, message, Toast.LENGTH_LONG).show();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(ChangePasswordActivity.this, "রেসপন্স পার্স এরর", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    error.printStackTrace();

                    String errorMsg = "নেটওয়ার্ক সমস্যা";
                    if (error.networkResponse != null) {
                        errorMsg = "সার্ভার এরর (Code: " + error.networkResponse.statusCode + ")";
                        Log.e(TAG, "Error response: " + new String(error.networkResponse.data));
                    }

                    Toast.makeText(ChangePasswordActivity.this, errorMsg, Toast.LENGTH_LONG).show();
                    Log.e(TAG, "Network error: " + error.getMessage());
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
                SessionManager session = new SessionManager(ChangePasswordActivity.this);
                String token = session.getToken();
                if (token != null && !token.isEmpty()) {
                    headers.put("Authorization", "Bearer " + token);
                }
                return headers;
            }

            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                // user_id no longer needed (server uses JWT), but send for backward compat
                params.put("old_password", oldPassword);
                params.put("new_password", newPassword);
                params.put("confirm_password", confirmPassword);

                Log.d(TAG, "Params: " + params.toString());
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
