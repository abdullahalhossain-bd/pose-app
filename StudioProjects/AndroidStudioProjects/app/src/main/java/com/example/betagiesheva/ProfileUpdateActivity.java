package com.example.betagiesheva;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
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
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

public class ProfileUpdateActivity extends AppCompatActivity {

    private de.hdodenhof.circleimageview.CircleImageView profileImage;
    private ImageView cameraIcon;
    private TextInputEditText nameInput, phoneInput, addressInput;
    private CardView submitButton;
    private com.airbnb.lottie.LottieAnimationView progressBar;

    private Bitmap selectedBitmap = null;
    private String imageBase64 = "";

    private SharedPreferences prefs;
    private String userId;

    private final ActivityResultLauncher<Intent> imagePickerLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    result -> {
                        if (result.getResultCode() == Activity.RESULT_OK && result.getData() != null) {
                            Uri uri = result.getData().getData();
                            try {
                                Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), uri);
                                selectedBitmap = resizeBitmap(bitmap, 1024);
                                profileImage.setImageBitmap(selectedBitmap);
                                imageBase64 = bitmapToBase64(selectedBitmap);
                            } catch (IOException e) {
                                Toast.makeText(this, "ছবি লোড করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                            }
                        }
                    }
            );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile_update);

        initViews();
        loadProfile();
        setupClicks();
    }

    private void initViews() {
        profileImage = findViewById(R.id.profileImage);
        cameraIcon = findViewById(R.id.cameraIcon);
        nameInput = findViewById(R.id.nameInput);
        phoneInput = findViewById(R.id.phoneInput);
        addressInput = findViewById(R.id.addressInput);
        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);

        prefs = getSharedPreferences("user_pref", Context.MODE_PRIVATE);
        userId = prefs.getString("id", "");
    }

    private void loadProfile() {
        if (userId.isEmpty()) return;

        // CRITICAL FIX: profile.php now requires JWT — use AuthRequest
        com.example.betagiesheva.helper.AuthRequest request = new com.example.betagiesheva.helper.AuthRequest(
                Request.Method.POST,
                Config.PROFILE_URL,
                response -> {
                    try {
                        JSONObject json = new JSONObject(response);
                        if (!json.optString("status").equals("success")) return;

                        JSONObject data = json.getJSONObject("data");
                        nameInput.setText(data.optString("name"));
                        phoneInput.setText(data.optString("phone"));
                        addressInput.setText(data.optString("address"));

                        String image = data.optString("image", "");
                        Glide.with(this)
                                .load(image)
                                .placeholder(R.drawable.profile)
                                .error(R.drawable.profile)
                                .into(profileImage);

                    } catch (Exception e) {
                        Toast.makeText(this, "প্রোফাইল লোড ব্যর্থ", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> Toast.makeText(this, "সার্ভার সমস্যা", Toast.LENGTH_SHORT).show(),
                this
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> map = new HashMap<>();
                map.put("user_id", String.valueOf(userId));
                return map;
            }
        };

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void setupClicks() {
        cameraIcon.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            intent.setType("image/*");
            imagePickerLauncher.launch(intent);
        });

        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                submitProfile();
            }
        });
    }

    private boolean validateForm() {
        if (TextUtils.isEmpty(nameInput.getText())) {
            nameInput.setError("নাম প্রয়োজন");
            return false;
        }
        return true;
    }

    private void hideKeyboard() {
        View view = getCurrentFocus();
        if (view != null) {
            InputMethodManager imm =
                    (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
        }
    }

    private Bitmap resizeBitmap(Bitmap bitmap, int maxSize) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        float ratio = (float) width / height;

        if (ratio > 1) {
            width = maxSize;
            height = (int) (width / ratio);
        } else {
            height = maxSize;
            width = (int) (height * ratio);
        }
        return Bitmap.createScaledBitmap(bitmap, width, height, true);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, baos);
        return "data:image/jpeg;base64," + android.util.Base64.encodeToString(baos.toByteArray(), android.util.Base64.NO_WRAP);
    }

    private void submitProfile() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.UPDATE_PROFILE_URL,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success")) {
                            Toast.makeText(this, json.optString("message"), Toast.LENGTH_SHORT).show();
                            // Update local shared prefs
                            prefs.edit().putString("name", nameInput.getText().toString().trim()).apply();
                            finish();
                        } else {
                            Toast.makeText(this, json.optString("message"), Toast.LENGTH_SHORT).show();
                        }
                    } catch (Exception e) {
                        Toast.makeText(this, "Response error", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    Toast.makeText(this, "Network error", Toast.LENGTH_SHORT).show();
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                params.put("user_id", userId);
                params.put("name", nameInput.getText().toString().trim());
                params.put("phone", phoneInput.getText().toString().trim());
                params.put("address", addressInput.getText().toString().trim());
                if (!TextUtils.isEmpty(imageBase64)) {
                    params.put("image", imageBase64);
                }
                return params;
            }

            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String utf8 = new String(response.data, "UTF-8");
                    return Response.success(
                            utf8,
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response)
                    );
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }
        };

        request.setRetryPolicy(new DefaultRetryPolicy(
                30000,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        ));

        Config.getInstance(this).addToRequestQueue(request);
    }
}
