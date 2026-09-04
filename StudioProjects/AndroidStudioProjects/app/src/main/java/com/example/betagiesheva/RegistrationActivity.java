package com.example.betagiesheva;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class RegistrationActivity extends AppCompatActivity {

    private static final String TAG = "RegistrationActivity";
    private static final int PICK_IMAGE_REQUEST = 1;
    private static final int MAX_IMAGE_SIZE = 800;

    private TextInputEditText etName, etPhone, etPassword, etAddress;
    private AutoCompleteTextView actvUnion;
    private CardView submitButton;
    private TextView loginShift;
    private LottieAnimationView progress;
    private CircleImageView profileImage;

    private Bitmap selectedBitmap;

    private final String[] unions = {
            "বিবিচিনি ইউনিয়ন পরিষদ",
            "বেতাগী সদর ইউনিয়ন পরিষদ",
            "হোসনাবাদ ইউনিয়ন পরিষদ",
            "মোকামিয়া ইউনিয়ন পরিষদ",
            "বুড়ামজুমদার ইউনিয়ন পরিষদ",
            "কাজিরাবাদ ইউনিয়ন পরিষদ",
            "সরিষামুড়ি ইউনিয়ন পরিষদ"
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_registration);

        initViews();
        setupUnionDropdown();
        setupClickListeners();
    }

    private void initViews() {
        etName = findViewById(R.id.etName);
        etPhone = findViewById(R.id.etPhone);
        etPassword = findViewById(R.id.etPassword);
        etAddress = findViewById(R.id.etAddress);
        actvUnion = findViewById(R.id.actvUnion);
        submitButton = findViewById(R.id.submitButton);
        loginShift = findViewById(R.id.loginActivityShift);
        progress = findViewById(R.id.progress);
        profileImage = findViewById(R.id.profileImage);
    }

    private void setupUnionDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this,
                android.R.layout.simple_dropdown_item_1line,
                unions
        );
        actvUnion.setAdapter(adapter);
    }

    private void setupClickListeners() {
        profileImage.setOnClickListener(v -> openGallery());
        submitButton.setOnClickListener(v -> registerUser());
        loginShift.setOnClickListener(v -> {
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == PICK_IMAGE_REQUEST
                && resultCode == Activity.RESULT_OK
                && data != null) {
            try {
                Uri uri = data.getData();
                Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), uri);
                selectedBitmap = resizeBitmap(bitmap, MAX_IMAGE_SIZE);
                profileImage.setImageBitmap(selectedBitmap);
            } catch (IOException e) {
                Log.e(TAG, "Image load error: " + e.getMessage());
                Toast.makeText(this, "ছবি লোড সমস্যা", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private Bitmap resizeBitmap(Bitmap bitmap, int maxSize) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        float ratio = Math.min((float) maxSize / width, (float) maxSize / height);
        return Bitmap.createScaledBitmap(bitmap,
                Math.round(width * ratio),
                Math.round(height * ratio),
                true);
    }

    private void registerUser() {

        String name = etName.getText() != null ? etName.getText().toString().trim() : "";
        String phone = etPhone.getText() != null ? etPhone.getText().toString().trim() : "";
        String password = etPassword.getText() != null ? etPassword.getText().toString().trim() : "";
        String address = etAddress.getText() != null ? etAddress.getText().toString().trim() : "";
        String union = actvUnion.getText() != null ? actvUnion.getText().toString().trim() : "";

        if (name.isEmpty() || phone.isEmpty() || password.isEmpty()
                || address.isEmpty() || union.isEmpty()) {
            Toast.makeText(this, "সব তথ্য পূরণ করুন", Toast.LENGTH_SHORT).show();
            return;
        }

        progress.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        StringRequest request = new StringRequest(
                Request.Method.POST,
                Config.REGISTER,

                response -> {
                    progress.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    Log.d(TAG, "Server response: " + response);

                    try {
                        JSONObject json = new JSONObject(response);

                        if (json.getBoolean("success")) {
                            JSONObject data = json.getJSONObject("data");
                            JSONObject user = data.getJSONObject("user");
                            String token = json.optString("token", "");

                            SessionManager sessionManager = new SessionManager(this);
                            // Use optString for id (server returns it as string) — getInt() is fragile.
                            // Also save the JWT token so the new user can immediately call write endpoints.
                            sessionManager.saveUser(
                                    user.optString("id", ""),
                                    user.optString("name", ""),
                                    user.optString("phone", ""),
                                    user.optString("address", ""),
                                    user.optString("union_name", ""),
                                    user.optString("image", "default.png"),
                                    user.optString("user_type", "user"),
                                    token
                            );

                            Toast.makeText(this, "রেজিস্ট্রেশন সফল", Toast.LENGTH_SHORT).show();
                            startActivity(new Intent(this, HomeActivity.class));
                            finish();

                        } else {
                            Toast.makeText(this,
                                    json.optString("message"),
                                    Toast.LENGTH_LONG).show();
                        }

                    } catch (Exception e) {
                        Log.e(TAG, "JSON parse error: " + e.getMessage() + " | Raw: " + response);
                        Toast.makeText(this, "JSON সমস্যা", Toast.LENGTH_SHORT).show();
                    }
                },

                error -> {
                    progress.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    int statusCode = -1;
                    String errorMessage = "সার্ভার সমস্যা, আবার চেষ্টা করুন।"; // Default message

                    if (error.networkResponse != null) {
                        statusCode = error.networkResponse.statusCode;
                        try {
                            // সার্ভার থেকে আসা রRaw JSON ডাটা টেক্সটে রূপান্তর
                            String body = new String(error.networkResponse.data, "UTF-8");
                            Log.e(TAG, "Volley error | Status: " + statusCode + " | Body: " + body);

                            // JSON থেকে নির্দিষ্ট বাংলা মেসেজটি বের করা
                            JSONObject jsonObject = new JSONObject(body);
                            if (jsonObject.has("message")) {
                                errorMessage = jsonObject.getString("message");
                            }
                        } catch (Exception e) {
                            Log.e(TAG, "Error parsing error body: " + e.getMessage());
                        }
                    } else {
                        Log.e(TAG, "Volley error without network response: " + error.getMessage());
                    }

                    // ব্যবহারকারীকে সঠিক মেসেজটি দেখানো
                    Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show();
                }

        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> params = new HashMap<>();
                params.put("name", name);
                params.put("phone", phone);
                params.put("password", password);
                params.put("address", address);
                params.put("union", union);

                if (selectedBitmap != null) {
                    params.put("image", bitmapToBase64(selectedBitmap));
                }

                return params;
            }
        };

        request.setRetryPolicy(new DefaultRetryPolicy(30000, 0, 1f));
        Volley.newRequestQueue(this).add(request);
    }
    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 70, baos);
        return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP);
    }
}

