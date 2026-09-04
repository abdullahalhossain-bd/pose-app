package com.example.betagiesheva;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
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
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.Model.UnifiedGovtOfficer;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

public class AddUnifiedGovtOfficerActivity extends AppCompatActivity {

    private static final String TAG = "AddGovtOfficerActivity";

    // Officer type (from intent or edit data)
    private String officerType = "";

    // Views
    private ImageView govtOfficerImage, backButton;
    private TextInputEditText nameInput, rankInput, phoneInput;
    private CardView submitButton;
    private ProgressBar progressBar;

    // Edit mode
    private UnifiedGovtOfficer editingOfficer;
    private boolean isEditMode = false;

    // Image
    private String officerImageBase64 = "";
    private Bitmap selectedBitmap = null;
    private String name = "";
    private String rank = "";
    private String phone = "";


    // Image picker
    private final ActivityResultLauncher<Intent> imagePickerLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    result -> {
                        if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                            Uri uri = result.getData().getData();
                            try {
                                selectedBitmap = MediaStore.Images.Media.getBitmap(
                                        getContentResolver(), uri
                                );
                                govtOfficerImage.setImageBitmap(selectedBitmap);
                                officerImageBase64 = bitmapToBase64(selectedBitmap);
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
        setContentView(R.layout.activity_add_unified_govt_officer);

        // Get officer type from intent
        if (getIntent() != null) {
            officerType = getIntent().getStringExtra("officer_type");
        }
        if (officerType == null) officerType = "";

        initViews();
        setupClickListeners();
        checkForEditMode();
    }

    private void initViews() {
        govtOfficerImage = findViewById(R.id.govtOfficerImage);
        backButton = findViewById(R.id.topBackgroundImage);
        nameInput = findViewById(R.id.nameInput);
        rankInput = findViewById(R.id.rankInput);
        phoneInput = findViewById(R.id.phoneInput);
        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);

        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle("নতুন অফিসার যোগ করুন");
        }
    }

    private void setupClickListeners() {
        govtOfficerImage.setOnClickListener(v -> openGallery());

        if (backButton != null) {
            backButton.setOnClickListener(v -> finish());
        }

        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                submitForm();
            }
        });
    }

    private void checkForEditMode() {
        editingOfficer = (UnifiedGovtOfficer) getIntent().getSerializableExtra("govt_officer_data");

        if (editingOfficer != null) {
            isEditMode = true;

            if (getSupportActionBar() != null) {
                getSupportActionBar().setTitle(editingOfficer.getOfficerName() + " সম্পাদনা করুন");
            }

            nameInput.setText(editingOfficer.getOfficerName());
            rankInput.setText(editingOfficer.getRank());
            phoneInput.setText(editingOfficer.getMobileNumber());

            // Preserve officer type in edit mode
            if (!TextUtils.isEmpty(editingOfficer.getOfficerType())) {
                officerType = editingOfficer.getOfficerType();
            }

            if (!TextUtils.isEmpty(editingOfficer.getImage())) {
                Glide.with(this)
                        .load(editingOfficer.getImage())
                        .placeholder(R.drawable.baseline_library_add_24)
                        .error(R.drawable.baseline_library_add_24)
                        .into(govtOfficerImage);
            }
        }
    }

    private boolean validateForm() {
        String name = nameInput.getText().toString().trim();
        String rank = rankInput.getText().toString().trim();
        String phone = phoneInput.getText().toString().trim();

        if (TextUtils.isEmpty(name)) {
            Toast.makeText(this, "অফিসারের নাম দিন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (TextUtils.isEmpty(officerType)) {
            Toast.makeText(this, "অফিসারের ধরন নির্ধারিত নেই", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (TextUtils.isEmpty(rank)) {
            Toast.makeText(this, "পদবী দিন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (TextUtils.isEmpty(phone)) {
            Toast.makeText(this, "মোবাইল নম্বর দিন", Toast.LENGTH_SHORT).show();
            return false;
        }

        return true;
    }

    private void submitForm() {
        name = nameInput.getText().toString().trim();
        rank = rankInput.getText().toString().trim();
        phone = phoneInput.getText().toString().trim();


        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        String url = isEditMode
                ? Config.BASE_URL + "update_unified_govt_officer.php"
                : Config.BASE_URL + "add_unified_govt_officer.php";

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                url,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    try {
                        Object parsed = new JSONTokener(response.trim()).nextValue();
                        if (!(parsed instanceof JSONObject)) {
                            Toast.makeText(this, "সার্ভার ত্রুটি", Toast.LENGTH_SHORT).show();
                            return;
                        }

                        JSONObject json = (JSONObject) parsed;
                        if (json.optBoolean("success", false)) {
                            Toast.makeText(
                                    this,
                                    isEditMode ? "অফিসার আপডেট হয়েছে" : "অফিসার যোগ করা হয়েছে",
                                    Toast.LENGTH_SHORT
                            ).show();
                            setResult(RESULT_OK);
                            finish();
                        } else {
                            Toast.makeText(this,
                                    json.optString("message", "সংরক্ষণ ব্যর্থ"),
                                    Toast.LENGTH_SHORT).show();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(this, "রেসপন্স পার্স করতে সমস্যা", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    Toast.makeText(this, "নেটওয়ার্ক সমস্যা", Toast.LENGTH_LONG).show();
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();

                SessionManager sessionManager = new SessionManager(AddUnifiedGovtOfficerActivity.this);
                String userId = sessionManager.getId();

                params.put("user_id", userId != null ? userId : "1");
                params.put("name", name);
                params.put("officer_type", officerType);
                params.put("designation", rank);
                params.put("phone_number", phone);

                if (isEditMode && editingOfficer != null) {
                    params.put("id", editingOfficer.getId());
                }

                if (!TextUtils.isEmpty(officerImageBase64)) {
                    params.put("image", officerImageBase64);
                }

                Log.d(TAG, "Params: " + params);
                return params;
            }

            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String utf8 = new String(response.data, "UTF-8");
                    return Response.success(utf8,
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response));
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }
        };

        RetryPolicy policy = new DefaultRetryPolicy(
                30000,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        );
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        imagePickerLauncher.launch(intent);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, bos);
        return Base64.encodeToString(bos.toByteArray(), Base64.NO_WRAP);
    }

    private void hideKeyboard() {
        InputMethodManager imm =
                (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null && getCurrentFocus() != null) {
            imm.hideSoftInputFromWindow(getCurrentFocus().getWindowToken(), 0);
        }
    }
}
