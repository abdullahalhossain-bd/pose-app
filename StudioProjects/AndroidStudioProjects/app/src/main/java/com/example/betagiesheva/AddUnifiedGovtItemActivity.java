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
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.Model.UnifiedGovtItem;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class AddUnifiedGovtItemActivity extends AppCompatActivity {

    private static final String TAG = "AddUnifiedGovtItem";

    private ImageView govtItemImage, backButton;
    private TextInputEditText nameInput, addressInput, phoneInput;
    private AutoCompleteTextView unionDropdown;
    private CardView submitButton;
    private ProgressBar progressBar;

    private UnifiedGovtItem editingItem;
    private boolean isEditMode = false;

    // 🔥 item type will come ONLY from intent or edit item
    private String itemTypeEnglish = "";

    private String itemImageBase64 = "";
    private Bitmap selectedBitmap = null;

    private final String[] unionNames = {
            "বিবিচিনি ইউনিয়ন পরিষদ",
            "বেতাগী সদর ইউনিয়ন পরিষদ",
            "হোসনাবাদ ইউনিয়ন পরিষদ",
            "মোকামিয়া ইউনিয়ন পরিষদ",
            "বুড়ামজুমদার ইউনিয়ন পরিষদ",
            "কাজিরাবাদ ইউনিয়ন পরিষদ",
            "সরিষামুড়ি ইউনিয়ন পরিষদ"
    };

    // ================= IMAGE PICKER =================
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
                                govtItemImage.setImageBitmap(selectedBitmap);
                                itemImageBase64 = bitmapToBase64(selectedBitmap);
                            } catch (IOException e) {
                                e.printStackTrace();
                                toast("ছবি লোড ব্যর্থ");
                            }
                        }
                    }
            );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_unified_govt_item);

        initViews();
        setupUnionDropdown();
        setupClickListeners();
        resolveItemTypeFromIntent();
        checkForEditMode();
        setupTitle();
    }

    // ================= INIT =================
    private void initViews() {
        govtItemImage = findViewById(R.id.govtItemImage);
        backButton = findViewById(R.id.topBackgroundImage);
        nameInput = findViewById(R.id.nameInput);
        addressInput = findViewById(R.id.addressInput);
        unionDropdown = findViewById(R.id.unionDropdown);
        phoneInput = findViewById(R.id.phoneInput);
        submitButton = findViewById(R.id.submitButton);
        progressBar = findViewById(R.id.progress);
    }

    private void setupUnionDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this,
                android.R.layout.simple_dropdown_item_1line,
                unionNames
        );
        unionDropdown.setAdapter(adapter);
    }

    private void setupClickListeners() {
        govtItemImage.setOnClickListener(v -> openGallery());
        backButton.setOnClickListener(v -> finish());

        submitButton.setOnClickListener(v -> {
            if (validateForm()) {
                submitForm();
            }
        });
    }

    // ================= ITEM TYPE =================
    private void resolveItemTypeFromIntent() {
        String govtType = getIntent().getStringExtra("govtType");
        if (!TextUtils.isEmpty(govtType)) {
            itemTypeEnglish = govtType;
        }
    }

    // ================= EDIT MODE =================
    private void checkForEditMode() {
        editingItem = (UnifiedGovtItem) getIntent().getSerializableExtra("govt_item_data");

        if (editingItem != null) {
            isEditMode = true;

            nameInput.setText(editingItem.getName());
            addressInput.setText(editingItem.getAddress());
            phoneInput.setText(editingItem.getPhoneNumber());
            unionDropdown.setText(editingItem.getUnion(), false);

            if (editingItem.getItemType() != null) {
                itemTypeEnglish = editingItem.getItemType().name().toLowerCase();
            }

            if (!TextUtils.isEmpty(editingItem.getImgUrl())) {
                Glide.with(this)
                        .load(editingItem.getImgUrl())
                        .into(govtItemImage);
            }
        }
    }

    private void setupTitle() {
        if (getSupportActionBar() == null) return;

        if (isEditMode) {
            getSupportActionBar().setTitle("সংস্থা সম্পাদনা করুন");
        } else {
            getSupportActionBar().setTitle("নতুন সংস্থা যোগ করুন");
        }
    }

    // ================= VALIDATION =================
    private boolean validateForm() {

        String name = nameInput.getText().toString().trim();

        if (TextUtils.isEmpty(name)) {
            toast("সংস্থার নাম দিন");
            return false;
        }

        if (!containsBangla(name)) {
            toast("সংস্থার নাম অবশ্যই বাংলায় হতে হবে");
            return false;
        }

        if (TextUtils.isEmpty(addressInput.getText())) {
            toast("ঠিকানা দিন");
            return false;
        }

        if (TextUtils.isEmpty(unionDropdown.getText())) {
            toast("ইউনিয়ন নির্বাচন করুন");
            return false;
        }

        if (TextUtils.isEmpty(phoneInput.getText())) {
            toast("ফোন নম্বর দিন");
            return false;
        }

        if (TextUtils.isEmpty(itemTypeEnglish)) {
            toast("আইটেম টাইপ পাওয়া যায়নি");
            return false;
        }

        return true;
    }

    // ================= SUBMIT =================
    private void submitForm() {

        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        String url = isEditMode
                ? Config.UPDATE_UNIFIED_GOVT_ITEM
                : Config.ADD_UNIFIED_GOVT_ITEM;

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                url,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    toast(isEditMode ? "আপডেট সফল" : "যোগ সফল");
                    finish();
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    toast("নেটওয়ার্ক সমস্যা");
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() {

                SessionManager sm = new SessionManager(AddUnifiedGovtItemActivity.this);
                Map<String, String> params = new HashMap<>();

                params.put("user_id", sm.getId());
                params.put("name", nameInput.getText().toString().trim());
                params.put("item_type", itemTypeEnglish);
                params.put("address", addressInput.getText().toString().trim());
                params.put("union", unionDropdown.getText().toString().trim());
                params.put("phone", phoneInput.getText().toString().trim());

                if (isEditMode && editingItem != null) {
                    params.put("id", String.valueOf(editingItem.getId()));
                }

                if (!TextUtils.isEmpty(itemImageBase64)) {
                    params.put("image", itemImageBase64);
                }

                Log.d(TAG, "Params: " + params);
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

    // ================= HELPERS =================
    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        imagePickerLauncher.launch(intent);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, out);
        return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP);
    }

    private boolean containsBangla(String value) {
        for (char c : value.toCharArray()) {
            if (c >= 0x0980 && c <= 0x09FF) return true;
        }
        return false;
    }

    private void hideKeyboard() {
        View view = getCurrentFocus();
        if (view != null) {
            InputMethodManager imm =
                    (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
        }
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
    }
}
