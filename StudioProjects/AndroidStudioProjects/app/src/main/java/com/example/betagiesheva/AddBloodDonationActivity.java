package com.example.betagiesheva;

import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Model.Donor;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class AddBloodDonationActivity extends AppCompatActivity {

    private static final String TAG = "AddBloodDonationActivity";

    // Views
    private androidx.appcompat.widget.AppCompatImageView donorImage;
    private TextInputEditText nameInput, addressInput, phoneInput;
    private AutoCompleteTextView bloodGroupDropdown;
    private CardView submitButton;
    private ProgressDialog progressDialog;

    // Image
    private Bitmap selectedBitmap = null;
    private String donorImageBase64 = "";

    // Edit Mode
    private Donor editingDonor;
    private boolean isEditMode = false;

    // Blood Group Options
    private final String[] BLOOD_GROUPS = {"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"};

    // Image Picker — single declaration only
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
                                donorImage.setImageBitmap(selectedBitmap);
                            } catch (IOException e) {
                                Toast.makeText(this, "ছবি লোড করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                            }
                        }
                    }
            );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_blood_donation);

        initViews();
        setupBloodGroupDropdown();
        setupClickListeners();
        checkForEditMode();
    }

    // ──────────────── Init ────────────────
    private void initViews() {
        donorImage = findViewById(R.id.donorImage);
        nameInput = findViewById(R.id.nameInput);
        bloodGroupDropdown = findViewById(R.id.bloodGroupDropdown);
        addressInput = findViewById(R.id.addressInput);
        phoneInput = findViewById(R.id.phoneInput);
        submitButton = findViewById(R.id.submitButton);
    }

    // ──────────────── Setup ────────────────
    private void setupBloodGroupDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, R.layout.dropdown_item, BLOOD_GROUPS);
        bloodGroupDropdown.setAdapter(adapter);
    }




    private void setupClickListeners() {
        donorImage.setOnClickListener(v -> {
            hideKeyboard();
            Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            intent.setType("image/*");
            imagePickerLauncher.launch(intent);
        });

        submitButton.setOnClickListener(v -> validateAndSubmit());
    }

    // ──────────────── Edit Mode ────────────────
    private void checkForEditMode() {
        editingDonor = getIntent().getParcelableExtra("donor_data");
        if (editingDonor == null) return;

        isEditMode = true;
        nameInput.setText(editingDonor.getName());
        bloodGroupDropdown.setText(editingDonor.getBloodGroup(), false);
        addressInput.setText(editingDonor.getAddress());
        phoneInput.setText(editingDonor.getPhone());
    }

    // ──────────────── Validation ────────────────
    private void validateAndSubmit() {
        String name = nameInput.getText() != null ? nameInput.getText().toString().trim() : "";
        String bloodGroup = bloodGroupDropdown.getText() != null ? bloodGroupDropdown.getText().toString().trim() : "";
        String address = addressInput.getText() != null ? addressInput.getText().toString().trim() : "";
        String phone = phoneInput.getText() != null ? phoneInput.getText().toString().trim() : "";

        if (name.isEmpty()) {
            nameInput.setError("নাম প্রয়োজন");
            return;
        }
        if (bloodGroup.isEmpty()) {
            bloodGroupDropdown.setError("রক্তের গ্রুপ নির্বাচন করুন");
            return;
        }
        if (address.isEmpty()) {
            addressInput.setError("ঠিকানা প্রয়োজন");
            return;
        }
        if (phone.isEmpty()) {
            phoneInput.setError("ফোন নম্বর প্রয়োজন");
            return;
        }
        if (phone.length() < 10) {
            phoneInput.setError("বৈধ ফোন নম্বর দিন");
            return;
        }

        addDonor(name, bloodGroup, address, phone);
    }

    // ──────────────── API Call ────────────────
    private void addDonor(String name, String bloodGroup, String address, String phone) {
        progressDialog = new ProgressDialog(this);
        progressDialog.setMessage("জমা দেওয়া হচ্ছে...");
        progressDialog.setCancelable(false);
        progressDialog.show();

        final String base64Image = getBase64Image();
        final String apiUrl = isEditMode ? Config.UPDATE_DONOR : Config.ADD_DONOR;

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                apiUrl,
                response -> {
                    progressDialog.dismiss();
                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.getBoolean("success")) {
                            Toast.makeText(this, json.getString("message"), Toast.LENGTH_LONG).show();
                            hideKeyboard();
                            setResult(RESULT_OK);
                            finish();
                        } else {
                            String message = json.optString("message", "ব্যর্থ হয়েছে।");
                            // Handle validation errors array if present
                            if (json.has("errors")) {
                                message = json.getJSONArray("errors").join(", ").toString();
                            }
                            Toast.makeText(this, message, Toast.LENGTH_LONG).show();
                        }
                    } catch (Exception e) {
                        Toast.makeText(this, "রেসপন্স এরর।", Toast.LENGTH_LONG).show();
                        Log.e(TAG, "Response error", e);
                    }
                },
                error -> {
                    progressDialog.dismiss();
                    Toast.makeText(this, "নেটওয়ার্ক এরর।", Toast.LENGTH_LONG).show();
                    Log.e(TAG, "Network error", error);
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                
                if (isEditMode && editingDonor != null) {
                    params.put("id", editingDonor.getId());
                }
                
                params.put("name", name);
                params.put("blood_group", bloodGroup);
                params.put("address", address);
                params.put("phone", phone);
                
                if (base64Image != null && !base64Image.isEmpty()) {
                    params.put("image", base64Image);
                }
                
                return params;
            }
        };

        request.setRetryPolicy(new DefaultRetryPolicy(
                30000, 1, 1.0f
        ));

        Config.getInstance(this).addToRequestQueue(request);
    }

    // ──────────────── Helper ────────────────
    private String getBase64Image() {
        if (selectedBitmap == null) return null;
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        selectedBitmap.compress(Bitmap.CompressFormat.JPEG, 80, baos);
        return Base64.encodeToString(baos.toByteArray(), Base64.DEFAULT);
    }

    private void hideKeyboard() {
        View v = getCurrentFocus();
        if (v != null) {
            ((InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE))
                    .hideSoftInputFromWindow(v.getWindowToken(), 0);
        }
    }
}
