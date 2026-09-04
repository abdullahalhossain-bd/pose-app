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
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AlertDialog;
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
import com.example.betagiesheva.Model.UnifiedBusinessItem;
import com.example.betagiesheva.helper.AuthRequest;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class AddUnifiedBusinessItemActivity extends AppCompatActivity {
    private static final String TAG = "AddBusinessActivity";

    private String businessType = "";
    private String displayName = "";

    private ImageView shopImage, backButton;
    private EditText nameEditText;
    private EditText proprietorNameEditText;
    private EditText detailsEditText;
    private EditText addressEditText;
    private AutoCompleteTextView unionDropdown;
    private EditText phoneEditText;
    private CardView submitButton;
    private CardView deleteButton;
    private ProgressBar progressBar;
    private SessionManager sessionManager;
    private boolean isAdmin = false;

    // Edit mode
    private UnifiedBusinessItem editingItem;
    private boolean isEditMode = false;
    private String businessImageBase64 = "";
    private Bitmap selectedBitmap = null;

    // Union names array
    private final String[] unionNames = {
            "বিবিচিনি ইউনিয়ন পরিষদ",
            "বেতাগী সদর ইউনিয়ন পরিষদ",
            "হোসনাবাদ ইউনিয়ন পরিষদ",
            "মোকামিয়া ইউনিয়ন পরিষদ",
            "বুড়ামজুমদার ইউনিয়ন পরিষদ",
            "কাজিরাবাদ ইউনিয়ন পরিষদ",
            "সরিষামুড়ি ইউনিয়ন পরিষদ"
    };

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
                                shopImage.setImageBitmap(selectedBitmap);
                                businessImageBase64 = bitmapToBase64(selectedBitmap);
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
        setContentView(R.layout.activity_add_unified_business_item);

        if (getIntent() != null) {
            businessType = getIntent().getStringExtra("businessType");
            displayName = getIntent().getStringExtra("displayName");
        }

        if (businessType == null) businessType = "";
        if (displayName == null) displayName = "";

        init();
        setupUnionDropdown();
        setupClickListeners();
        checkForEditMode();
        setupAdminControls();
    }

    private void init() {
        shopImage = findViewById(R.id.ShopImage);
        backButton = findViewById(R.id.back_button);
        nameEditText = findViewById(R.id.Name);
        proprietorNameEditText = findViewById(R.id.proprietor_name);
        detailsEditText = findViewById(R.id.Details);
        addressEditText = findViewById(R.id.Address);
        unionDropdown = findViewById(R.id.unionDropdown);
        phoneEditText = findViewById(R.id.productNumber);
        submitButton = findViewById(R.id.submitButton);
        deleteButton = findViewById(R.id.deleteButton);
        progressBar = findViewById(R.id.progress);

        // Set activity title
        if (getSupportActionBar() != null) {
            if (isEditMode) {
                getSupportActionBar().setTitle("সম্পাদনা করুন");
            } else if (!TextUtils.isEmpty(displayName)) {
                getSupportActionBar().setTitle("নতুন " + displayName + " যোগ করুন");
            } else {
                getSupportActionBar().setTitle("নতুন ব্যবসা যোগ করুন");
            }
        }
    }

    private void setupUnionDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this,
                android.R.layout.simple_dropdown_item_1line, unionNames);
        unionDropdown.setAdapter(adapter);
    }

    private void setupClickListeners() {
        // Shop image click listener
        shopImage.setOnClickListener(v -> openGallery());

        // Back button
        if (backButton != null) {
            backButton.setOnClickListener(v -> finish());
        }

        // Submit button click listener
        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                submitForm();
            }
        });

        if (deleteButton != null) {
            deleteButton.setOnClickListener(v -> confirmDelete());
        }
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        imagePickerLauncher.launch(intent);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }

    private void checkForEditMode() {
        editingItem = getIntent().getParcelableExtra("business_data");
        if (editingItem != null) {
            isEditMode = true;

            if (getSupportActionBar() != null) {
                getSupportActionBar().setTitle(editingItem.getName() + " সম্পাদনা করুন");
            }

            // Populate form with existing data
            nameEditText.setText(editingItem.getName());
            proprietorNameEditText.setText(editingItem.getProprietorName());
            detailsEditText.setText(editingItem.getDetails());
            addressEditText.setText(editingItem.getAddress());
            phoneEditText.setText(editingItem.getPhone());

            // Set union dropdown if available
            if (!TextUtils.isEmpty(editingItem.getUnionName())) {
                int unionIndex = Arrays.asList(unionNames).indexOf(editingItem.getUnionName());
                if (unionIndex >= 0) {
                    unionDropdown.setText(editingItem.getUnionName(), false);
                }
            }

            // Load existing image
            if (!TextUtils.isEmpty(editingItem.getImage())) {
                Glide.with(this)
                        .load(editingItem.getImage())
                        .placeholder(R.drawable.allshop)
                        .error(R.drawable.allshop)
                        .into(shopImage);
            }
        }
    }

    private void setupAdminControls() {
        sessionManager = new SessionManager(this);
        isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());

        if (isEditMode) {
            if (isAdmin) {
                submitButton.setVisibility(View.VISIBLE);
                if (deleteButton != null) deleteButton.setVisibility(View.VISIBLE);
            } else {
                submitButton.setVisibility(View.GONE);
                if (deleteButton != null) deleteButton.setVisibility(View.GONE);
            }
        }
    }

    private boolean validateForm() {
        String name = nameEditText.getText().toString().trim();
        String address = addressEditText.getText().toString().trim();
        String unionName = unionDropdown.getText().toString().trim();
        String phone = phoneEditText.getText().toString().trim();

        if (TextUtils.isEmpty(name)) {
            Toast.makeText(this, "নাম দিন", Toast.LENGTH_SHORT).show();
            nameEditText.requestFocus();
            return false;
        }

        if (TextUtils.isEmpty(address)) {
            Toast.makeText(this, "ঠিকানা দিন", Toast.LENGTH_SHORT).show();
            addressEditText.requestFocus();
            return false;
        }

        if (TextUtils.isEmpty(unionName)) {
            Toast.makeText(this, "ইউনিয়ন নির্বাচন করুন", Toast.LENGTH_SHORT).show();
            unionDropdown.requestFocus();
            return false;
        }

        if (TextUtils.isEmpty(phone)) {
            Toast.makeText(this, "ফোন নম্বর দিন", Toast.LENGTH_SHORT).show();
            phoneEditText.requestFocus();
            return false;
        }

        return true;
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

    private void submitForm() {
        // Get form values
        String name = nameEditText.getText().toString().trim();
        String proprietorName = proprietorNameEditText.getText().toString().trim();
        String details = detailsEditText.getText().toString().trim();
        String address = addressEditText.getText().toString().trim();
        String unionName = unionDropdown.getText().toString().trim();
        String phone = phoneEditText.getText().toString().trim();
        String businessTypeToSend = resolveBusinessTypeForSubmit();

        // Show progress
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        // Determine URL based on mode
        String url = isEditMode
                ? Config.UPDATE_UNIFIED_BUSINESS_ITEM
                : Config.Add_BUSINESS_ITEMS_URL;

        Log.d(TAG, "Submitting to: " + url);
        Log.d(TAG, "Mode: " + (isEditMode ? "UPDATE" : "ADD"));

        // Create and send request
        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                url,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    Log.d(TAG, "Response: " + response);

                    try {
                        JSONObject jsonObject = new JSONObject(response);
                        boolean success = jsonObject.optBoolean("success", false);

                        if (success) {
                            String successMsg = isEditMode
                                    ? "ব্যবসা সফলভাবে আপডেট করা হয়েছে"
                                    : "ব্যবসা সফলভাবে যোগ করা হয়েছে";
                            Toast.makeText(this, successMsg, Toast.LENGTH_SHORT).show();
                            setResult(RESULT_OK);
                            finish(); // Close activity and return to previous
                        } else {
                            String message = jsonObject.optString("message", "সংরক্ষণ ব্যর্থ হয়েছে");
                            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Log.e(TAG, "JSON parsing error: " + e.getMessage());
                        Toast.makeText(this, "রেসপন্স পার্স করতে সমস্যা হয়েছে", Toast.LENGTH_SHORT).show();
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

                    Toast.makeText(this, errorMsg, Toast.LENGTH_LONG).show();
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

                // Get user ID from session
                SessionManager sessionManager = new SessionManager(AddUnifiedBusinessItemActivity.this);
                String userId = sessionManager.getId();

                params.put("user_id", userId != null ? userId : "1");
                params.put("name", name);
                params.put("proprietor_name", proprietorName);
                params.put("phone", phone);
                params.put("address", address);
                params.put("union_name", unionName);
                params.put("business_type", businessTypeToSend);
                params.put("details", details);

                // Add ID if editing
                if (isEditMode && editingItem != null) {
                    params.put("id", editingItem.getId());
                }

                // Only add image if a new one was selected
                if (!TextUtils.isEmpty(businessImageBase64)) {
                    params.put("image", businessImageBase64);
                }

                Log.d(TAG, "Params: " + params.toString());
                return params;
            }
        };

        // Set timeout and retry policy
        int socketTimeout = 30000; // 30 seconds
        RetryPolicy policy = new DefaultRetryPolicy(
                socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        );
        request.setRetryPolicy(policy);

        // Add to request queue
        Config.getInstance(this).addToRequestQueue(request);
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Update title if in edit mode
        if (isEditMode && editingItem != null && getSupportActionBar() != null) {
            getSupportActionBar().setTitle(editingItem.getName() + " সম্পাদনা করুন");
        }
    }
    // ================= DELETE =================
    private void confirmDelete() {
        if (editingItem == null) return;

        new AlertDialog.Builder(this)
                .setTitle("ডিলিট নিশ্চিত করুন")
                .setMessage("এই ব্যবসাটি ডিলিট করতে চান?")
                .setPositiveButton("হ্যাঁ", (d, w) -> deleteBusiness())
                .setNegativeButton("না", null)
                .show();
    }

    private void deleteBusiness() {
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);
        if (deleteButton != null) deleteButton.setEnabled(false);

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.DELETE_UNIFIED_BUSINESS_ITEM,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(this, "ডিলিট হয়েছে", Toast.LENGTH_SHORT).show();
                    finish();
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    if (deleteButton != null) deleteButton.setEnabled(true);
                    Toast.makeText(this, "ডিলিট ব্যর্থ", Toast.LENGTH_SHORT).show();
                    Log.e(TAG, "delete error", error);
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                params.put("id", editingItem.getId());
                return params;
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(
                socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        );
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }

    private String resolveBusinessTypeForSubmit() {
        String type = businessType != null ? businessType.trim() : "";

        if (TextUtils.isEmpty(type) && isEditMode && editingItem != null) {
            type = editingItem.getBusinessType() != null ? editingItem.getBusinessType().trim() : "";
        }

        if (containsBangla(type)) {
            return type;
        }

        if (containsBangla(displayName)) {
            return displayName.trim();
        }

        switch (type) {
            case "pharmacy":
                return "ফার্মেসী";
            case "ambulance":
                return "অ্যাম্বুলেন্স";
            case "hotels":
            case "hotel":
                return "হোটেল";
            case "nursery":
                return "নার্সারি দোকান";
            case "restaurant":
                return "রেস্টুরেন্ট";
            case "beauty_parlor":
                return "বিউটি পার্লার";
            case "training_center":
                return "প্রশিক্ষণ কেন্দ্র";
            case "online_services":
                return "অনলাইন সার্ভিস";
            case "tuition_services":
                return "টিউশন সার্ভিস";
            case "carpenter":
                return "কাঠমিস্ত্রী";
            case "building_contractor":
                return "রাজমিস্ত্রী";
            case "painter":
                return "রং মিস্ত্রী";
            case "car_mechanic":
            case "mechanic":
                return "গাড়ি মেকার";
            case "electrician":
                return "ইলেকট্রিক্যাল মেকার";
            case "tailor":
                return "দর্জি কারিগর";
            case "grocery":
            case "grocery_shop":
                return "মুদি দোকান";
            case "electronics":
            case "electronics_shop":
                return "ইলেকট্রনিক্স দোকান";
            case "jewelry":
            case "jewelers_shop":
                return "জুয়েলার্স দোকান";
            case "furniture":
            case "furniture_shop":
                return "ফার্নিচার দোকান";
            case "clothing":
            case "clothing_shop":
                return "কাপড়ের দোকান";
            case "concrete":
            case "concrete_shop":
                return "কংক্রিট দোকান";
            case "decoration":
            case "decorator_shop":
                return "ডেকোরেটরস দোকান";
            case "library":
                return "লাইব্রেরি";
            default:
                return type;
        }
    }

    private boolean containsBangla(String value) {
        if (TextUtils.isEmpty(value)) return false;
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (c >= 0x0980 && c <= 0x09FF) {
                return true;
            }
        }
        return false;
    }
}
