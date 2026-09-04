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
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
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
import com.example.betagiesheva.Model.UnifiedPerson;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

public class AddUnifiedPersonActivity extends AppCompatActivity {

    private static final String TAG = "AddUnifiedPersonActivity";

    // UI Components
    private TextInputEditText etName, etAddress, etPhone;
    private AutoCompleteTextView unionDropdown;
    private TextInputLayout nameInputLayout, addressInputLayout, unionInputLayout;
    private CardView submitButton;
    private ProgressBar progressBar;
    private ImageView shopImage;

    // Data
    private String personType = "";
    private String displayName = "";

    // Edit mode
    private UnifiedPerson editingPerson;
    private boolean isEditMode = false;
    private String personImageBase64 = "";
    private Bitmap selectedBitmap = null;

    // Union names
    String[] unionNames = {
            "বিবিচিনি ইউনিয়ন পরিষদ",
            "বেতাগী সদর ইউনিয়ন পরিষদ",
            "হোসনাবাদ ইউনিয়ন পরিষদ",
            "মোকামিয়া ইউনিয়ন পরিষদ",
            "বুড়ামজুমদার ইউনিয়ন পরিষদ",
            "কাজিরাবাদ ইউনিয়ন পরিষদ",
            "সরিষামুড়ি ইউনিয়ন পরিষদ"
    };

    // Image Picker Launcher
    private final ActivityResultLauncher<String> imagePickerLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.GetContent(),
                    uri -> {
                        if (uri != null) {
                            try {
                                selectedBitmap = MediaStore.Images.Media.getBitmap(
                                        getContentResolver(), uri
                                );
                                shopImage.setImageBitmap(selectedBitmap);
                                personImageBase64 = bitmapToBase64(selectedBitmap);
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
        setContentView(R.layout.activity_add_unified_person);

        // Get data from intent
        personType = getIntent().getStringExtra("personType");
        displayName = getIntent().getStringExtra("displayName");

        if (personType == null || personType.isEmpty()) {
            Toast.makeText(this, "Invalid person type", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        initViews();
        setupUnionDropdown();
        setupClickListeners();
        checkForEditMode();
    }

    private void initViews() {
        etName = findViewById(R.id.Name);
        etAddress = findViewById(R.id.Address);
        etPhone = findViewById(R.id.productNumber);
        unionDropdown = findViewById(R.id.unionDropdown);

        nameInputLayout = findViewById(R.id.nameInputLayout);
        addressInputLayout = findViewById(R.id.addressInputLayout);
        unionInputLayout = findViewById(R.id.unionInputLayout);

        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);
        shopImage = findViewById(R.id.ShopImage);

        // Set title
        if (getSupportActionBar() != null) {
            if (isEditMode) {
                getSupportActionBar().setTitle("সম্পাদনা করুন");
            } else {
                getSupportActionBar().setTitle("নতুন " + displayName + " যোগ করুন");
            }
        }
    }

    private void setupUnionDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this,
                android.R.layout.simple_dropdown_item_1line, unionNames);
        unionDropdown.setAdapter(adapter);
    }

    private void setupClickListeners() {
        submitButton.setOnClickListener(v -> {
            if (validateInputs()) {
                submitData();
            }
        });

        // Image click to upload
        shopImage.setOnClickListener(v -> imagePickerLauncher.launch("image/*"));
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }

    private void checkForEditMode() {
        editingPerson = getIntent().getParcelableExtra("person_data");
        if (editingPerson != null) {
            isEditMode = true;
            if (getSupportActionBar() != null) {
                getSupportActionBar().setTitle(editingPerson.getName() + " সম্পাদনা করুন");
            }
            // Populate form with existing data
            etName.setText(editingPerson.getName());
            etAddress.setText(editingPerson.getAddress());
            etPhone.setText(editingPerson.getPhone());

            // Set union dropdown if available
            int unionIndex = indexOf(unionNames, editingPerson.getUnion());
            if (unionIndex >= 0) {
                unionDropdown.setText(editingPerson.getUnion(), false);
            }

            // Load existing image
            if (!TextUtils.isEmpty(editingPerson.getImageUrl())) {
                Glide.with(this)
                        .load(editingPerson.getImageUrl())
                        .placeholder(R.drawable.alldepartment)
                        .error(R.drawable.alldepartment)
                        .into(shopImage);
                personImageBase64 = editingPerson.getImageUrl();
            }
        }
    }

    private int indexOf(String[] array, String value) {
        if (array == null || value == null) return -1;
        for (int i = 0; i < array.length; i++) {
            if (array[i].equals(value)) {
                return i;
            }
        }
        return -1;
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

    private boolean validateInputs() {
        boolean isValid = true;

        // Validate name
        if (etName.getText() == null || etName.getText().toString().trim().isEmpty()) {
            nameInputLayout.setError("নাম দিতে হবে");
            isValid = false;
        } else {
            nameInputLayout.setError(null);
        }

        // Validate address
        if (etAddress.getText() == null || etAddress.getText().toString().trim().isEmpty()) {
            addressInputLayout.setError("ঠিকানা দিতে হবে");
            isValid = false;
        } else {
            addressInputLayout.setError(null);
        }

        // Validate phone
        if (etPhone.getText() == null || etPhone.getText().toString().trim().isEmpty()) {
            Toast.makeText(this, "ফোন নম্বর দিতে হবে", Toast.LENGTH_SHORT).show();
            isValid = false;
        }

        // Validate union
        if (unionDropdown.getText() == null || unionDropdown.getText().toString().trim().isEmpty()) {
            unionInputLayout.setError("ইউনিয়ন নির্বাচন করতে হবে");
            isValid = false;
        } else {
            unionInputLayout.setError(null);
        }

        return isValid;
    }

    private void submitData() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        String name = etName.getText().toString().trim();
        String address = etAddress.getText().toString().trim();
        String phone = etPhone.getText().toString().trim();
        String union = unionDropdown.getText().toString().trim();

        // Determine URL based on mode
        String url = isEditMode ? Config.UPDATE_UNIFIED_PERSON : Config.ADD_UNIFIED_PERSON_URL;

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                url,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    try {
                        JSONObject jsonObject = new JSONObject(response);
                        boolean success = jsonObject.optBoolean("success", false);
                        String message = jsonObject.optString("message", "Unknown error");

                        if (success) {
                            String successMsg = isEditMode
                                    ? "ব্যক্তি সফলভাবে আপডেট করা হয়েছে"
                                    : message;
                            Toast.makeText(AddUnifiedPersonActivity.this, successMsg, Toast.LENGTH_SHORT).show();
                            setResult(RESULT_OK);
                            finish();
                        } else {
                            Toast.makeText(AddUnifiedPersonActivity.this, message, Toast.LENGTH_LONG).show();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(AddUnifiedPersonActivity.this, "Response parsing error", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    error.printStackTrace();
                    Toast.makeText(AddUnifiedPersonActivity.this, "Network error: " + error.getMessage(), Toast.LENGTH_LONG).show();
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                params.put("name", name);
                params.put("address", address);
                params.put("phone", phone);
                params.put("union", union);
                params.put("person_type", personType);

                // Add ID if editing
                if (isEditMode && editingPerson != null) {
                    params.put("id", editingPerson.getId());
                }

                // Only add image if a new one was selected
                if (!TextUtils.isEmpty(personImageBase64)) {
                    params.put("image", personImageBase64);
                }

                return params;
            }

            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                Map<String, String> headers = super.getHeaders();
                headers.put("Accept-Charset", "UTF-8");
                headers.put("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                return headers;
            }

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
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }
}
