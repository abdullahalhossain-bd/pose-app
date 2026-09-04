package com.example.betagiesheva;

import android.content.Context;
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
import android.widget.FrameLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class AddNoticeActivity extends AppCompatActivity {

    private static final String TAG = "AddNoticeActivity";

    private TextInputEditText titleInput, descriptionInput, dateInput, departmentInput;
    private AutoCompleteTextView noticeType;
    private CardView uploadImage, uploadDoc, submitNotice;
    private FrameLayout progressOverlay;
    private ProgressBar progressBar;
    private TextView imageStatusText, docStatusText;

    private Bitmap selectedBitmap;
    private String imageBase64 = "";
    private String documentBase64 = "";
    private String documentFileName = "";

    private final String[] noticeTypes = {"গুরুত্বপূর্ণ", "সাধারণ", "ইভেন্ট", "ছুটি"};

    // ================= IMAGE PICKER =================
    private final ActivityResultLauncher<String> imagePicker =
            registerForActivityResult(new ActivityResultContracts.GetContent(), uri -> {
                if (uri == null) return;
                try {
                    Bitmap bitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), uri);
                    selectedBitmap = resizeBitmap(bitmap);
                    imageBase64 = bitmapToBase64(selectedBitmap);
                    imageStatusText.setText("✓ যোগ হয়েছে");
                    imageStatusText.setTextColor(getResources().getColor(android.R.color.holo_green_dark));
                    Toast.makeText(this, "ছবি যুক্ত হয়েছে", Toast.LENGTH_SHORT).show();
                    Log.d(TAG, "Image selected and encoded to base64");
                } catch (Exception e) {
                    Log.e(TAG, "Error loading image", e);
                    imageStatusText.setText("(ব্যর্থ)");
                    imageStatusText.setTextColor(getResources().getColor(android.R.color.holo_red_dark));
                    Toast.makeText(this, "ছবি লোড ব্যর্থ: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });

    // ================= DOCUMENT PICKER =================
    private final ActivityResultLauncher<String[]> documentPicker =
            registerForActivityResult(new ActivityResultContracts.OpenDocument(), uri -> {
                if (uri == null) return;
                try {
                    documentBase64 = fileToBase64(uri);
                    documentFileName = getFileName(uri);
                    docStatusText.setText("✓ " + documentFileName);
                    docStatusText.setTextColor(getResources().getColor(android.R.color.holo_green_dark));
                    Toast.makeText(this, "ডকুমেন্ট যুক্ত হয়েছে", Toast.LENGTH_SHORT).show();
                    Log.d(TAG, "Document selected: " + documentFileName);
                } catch (Exception e) {
                    Log.e(TAG, "Error loading document", e);
                    docStatusText.setText("(ব্যর্থ)");
                    docStatusText.setTextColor(getResources().getColor(android.R.color.holo_red_dark));
                    Toast.makeText(this, "ডকুমেন্ট লোড ব্যর্থ: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_notice);

        initViews();
        setupDropdown();
        setupListeners();

        // Set current date
        String currentDate = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
        dateInput.setText(currentDate);

        Log.d(TAG, "AddNoticeActivity created");
    }

    private void initViews() {
        titleInput = findViewById(R.id.noticeTitle);
        descriptionInput = findViewById(R.id.description);
        departmentInput = findViewById(R.id.department);
        dateInput = findViewById(R.id.noticeDate);
        noticeType = findViewById(R.id.noticeType);

        uploadImage = findViewById(R.id.uploadImage);
        uploadDoc = findViewById(R.id.uploadDoc);
        submitNotice = findViewById(R.id.submitNotice);

        progressOverlay = findViewById(R.id.progressOverlay);
        progressBar = findViewById(R.id.progress);

        imageStatusText = findViewById(R.id.imageStatusText);
        docStatusText = findViewById(R.id.docStatusText);
    }

    private void setupDropdown() {
        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this,
                android.R.layout.simple_dropdown_item_1line,
                noticeTypes
        );
        noticeType.setAdapter(adapter);
        noticeType.setOnClickListener(v -> noticeType.showDropDown());
    }

    private void setupListeners() {
        uploadImage.setOnClickListener(v -> {
            Log.d(TAG, "Image upload clicked");
            imagePicker.launch("image/*");
        });

        uploadDoc.setOnClickListener(v -> {
            Log.d(TAG, "Document upload clicked");
            documentPicker.launch(new String[]{
                    "application/pdf",
                    "application/msword",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            });
        });

        submitNotice.setOnClickListener(v -> {
            if (validate()) {
                submitNotice();
            }
        });
    }

    private boolean validate() {
        if (TextUtils.isEmpty(titleInput.getText())) {
            titleInput.setError("শিরোনাম দিন");
            titleInput.requestFocus();
            return false;
        }
        if (TextUtils.isEmpty(descriptionInput.getText())) {
            descriptionInput.setError("বিবরণ দিন");
            descriptionInput.requestFocus();
            return false;
        }
        if (TextUtils.isEmpty(noticeType.getText())) {
            noticeType.setError("নোটিস টাইপ নির্বাচন করুন");
            noticeType.requestFocus();
            return false;
        }
        return true;
    }

    private void submitNotice() {
        hideKeyboard();
        showProgress();

        Log.d(TAG, "Submitting notice...");
        Log.d(TAG, "Title: " + titleInput.getText().toString());
        Log.d(TAG, "Type: " + noticeType.getText().toString());
        Log.d(TAG, "Has Image: " + !TextUtils.isEmpty(imageBase64));
        Log.d(TAG, "Has Document: " + !TextUtils.isEmpty(documentBase64));

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.ADD_NOTICE_URL,
                response -> {
                    hideProgress();
                    Log.d(TAG, "Response received: " + response);

                    try {
                        JSONObject obj = new JSONObject(response);
                        boolean success = obj.optBoolean("success", false);
                        String message = obj.optString("message", "Unknown response");

                        Toast.makeText(this, message, Toast.LENGTH_LONG).show();

                        if (success) {
                            Log.d(TAG, "Notice added successfully");
                            finish();
                        }

                    } catch (Exception e) {
                        Log.e(TAG, "Error parsing response", e);
                        Toast.makeText(this, "রেসপন্স পার্স এরর: " + e.getMessage(),
                                Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    hideProgress();
                    handleError(error);
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> params = new HashMap<>();
                params.put("title", titleInput.getText().toString().trim());
                params.put("description", descriptionInput.getText().toString().trim());
                params.put("type", noticeType.getText().toString().trim());
                params.put("department", departmentInput.getText().toString().trim());
                params.put("notice_date", dateInput.getText().toString().trim());

                if (!TextUtils.isEmpty(imageBase64)) {
                    params.put("image", imageBase64);
                    Log.d(TAG, "Image included in request");
                }

                if (!TextUtils.isEmpty(documentBase64)) {
                    params.put("document", documentBase64);
                    Log.d(TAG, "Document included in request");
                }

                return params;
            }

            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String responseString = new String(response.data, "UTF-8");
                    Log.d(TAG, "Raw response: " + responseString);
                    return Response.success(responseString, null);
                } catch (UnsupportedEncodingException e) {
                    Log.e(TAG, "Encoding error", e);
                    return super.parseNetworkResponse(response);
                }
            }
        };

        // Set timeout to 60 seconds
        request.setRetryPolicy(new DefaultRetryPolicy(
                60000,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        ));

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void handleError(VolleyError error) {
        Log.e(TAG, "Network error", error);

        String errorMessage = "নেটওয়ার্ক সমস্যা";

        if (error.networkResponse != null) {
            int statusCode = error.networkResponse.statusCode;
            Log.e(TAG, "Status code: " + statusCode);

            try {
                String responseBody = new String(error.networkResponse.data, "UTF-8");
                Log.e(TAG, "Error response: " + responseBody);

                JSONObject errorObj = new JSONObject(responseBody);
                errorMessage = errorObj.optString("message", errorMessage);
            } catch (Exception e) {
                Log.e(TAG, "Error parsing error response", e);
            }
        } else if (error.getCause() != null) {
            errorMessage = error.getCause().getMessage();
        }

        Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show();
    }

    // ================= HELPERS =================

    private void showProgress() {
        progressOverlay.setVisibility(View.VISIBLE);
        submitNotice.setEnabled(false);
    }

    private void hideProgress() {
        progressOverlay.setVisibility(View.GONE);
        submitNotice.setEnabled(true);
    }

    private Bitmap resizeBitmap(Bitmap bitmap) {
        int max = 1024;
        float ratio = Math.min(
                (float) max / bitmap.getWidth(),
                (float) max / bitmap.getHeight()
        );

        int newWidth = Math.round(bitmap.getWidth() * ratio);
        int newHeight = Math.round(bitmap.getHeight() * ratio);

        Log.d(TAG, "Resizing image from " + bitmap.getWidth() + "x" + bitmap.getHeight() +
                " to " + newWidth + "x" + newHeight);

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, baos);
        byte[] imageBytes = baos.toByteArray();

        Log.d(TAG, "Image size after compression: " + imageBytes.length + " bytes");

        return "data:image/jpeg;base64," + Base64.encodeToString(imageBytes, Base64.NO_WRAP);
    }

    private String fileToBase64(Uri uri) throws Exception {
        InputStream is = getContentResolver().openInputStream(uri);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int n;

        while ((n = is.read(buffer)) > 0) {
            baos.write(buffer, 0, n);
        }
        is.close();

        byte[] fileBytes = baos.toByteArray();
        Log.d(TAG, "Document size: " + fileBytes.length + " bytes");

        // Check file size (max 5MB)
        if (fileBytes.length > 5 * 1024 * 1024) {
            throw new Exception("ফাইল সাইজ ৫MB এর বেশি");
        }

        return "data:application/octet-stream;base64," +
                Base64.encodeToString(fileBytes, Base64.NO_WRAP);
    }

    private String getFileName(Uri uri) {
        String fileName = "document.pdf";
        try {
            String path = uri.getPath();
            if (path != null) {
                int cut = path.lastIndexOf('/');
                if (cut != -1) {
                    fileName = path.substring(cut + 1);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting file name", e);
        }
        return fileName;
    }

    private void hideKeyboard() {
        View v = getCurrentFocus();
        if (v != null) {
            InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
            }
        }
    }
}