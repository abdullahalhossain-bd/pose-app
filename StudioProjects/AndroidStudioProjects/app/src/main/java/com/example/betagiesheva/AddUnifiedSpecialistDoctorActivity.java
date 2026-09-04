package com.example.betagiesheva;

import android.app.TimePickerDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Base64;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TimePicker;
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
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

public class AddUnifiedSpecialistDoctorActivity extends AppCompatActivity {

    private ImageView doctorImage, backButton;
    private TextInputEditText nameInput, qualificationsInput, specializationInput,
            workplaceInput, chamberInput, visitingHoursInput, addressInput, phoneInput;
    private AutoCompleteTextView unionDropdown;
    private CardView submitButton;
    private ProgressBar progressBar;

    private Bitmap selectedBitmap = null;
    private String doctorImageBase64 = "";
    private String doctorType = "";

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
                                Bitmap bitmap = MediaStore.Images.Media.getBitmap(
                                        getContentResolver(), uri
                                );
                                selectedBitmap = resizeBitmap(bitmap, 1024);
                                doctorImage.setImageBitmap(selectedBitmap);
                                doctorImageBase64 = bitmapToBase64(selectedBitmap);

                                // Prevent >2MB upload
                                if (doctorImageBase64.length() > 2_500_000) {
                                    Toast.makeText(this, "ছবি অনেক বড়", Toast.LENGTH_SHORT).show();
                                    doctorImageBase64 = "";
                                    doctorImage.setImageResource(R.drawable.alldepartment);
                                }

                            } catch (IOException e) {
                                Toast.makeText(this, "ছবি লোড করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                            }
                        }
                    }
            );

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_unified_specialist_doctor);

        initViews();
        setupUnionDropdown();
        setupClickListeners();
        doctorType = getIntent().getStringExtra("doctor_type");
    }

    private void initViews() {
        doctorImage = findViewById(R.id.doctorImage);
        backButton = findViewById(R.id.topBackgroundImage);

        nameInput = findViewById(R.id.nameInput);
        qualificationsInput = findViewById(R.id.qualificationsInput);
        specializationInput = findViewById(R.id.specializationInput);
        workplaceInput = findViewById(R.id.workplaceInput);
        chamberInput = findViewById(R.id.chamberInput);
        visitingHoursInput = findViewById(R.id.visitingHoursInput);
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
        unionDropdown.setKeyListener(null); // force selection
    }

    private void setupClickListeners() {

        doctorImage.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_PICK,
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            intent.setType("image/*");
            imagePickerLauncher.launch(intent);
        });

        visitingHoursInput.setOnClickListener(v -> {
            Calendar c = Calendar.getInstance();
            new TimePickerDialog(
                    this,
                    (TimePicker view, int h, int m) ->
                            visitingHoursInput.setText(
                                    String.format("%02d:%02d", h, m)
                            ),
                    c.get(Calendar.HOUR_OF_DAY),
                    c.get(Calendar.MINUTE),
                    true
            ).show();
        });

        backButton.setOnClickListener(v -> finish());

        submitButton.setOnClickListener(v -> {
            if (validateForm()) submitForm();
        });
    }

    private boolean validateForm() {
        if (TextUtils.isEmpty(nameInput.getText())) {
            nameInput.setError("ডাক্তারের নাম দিন");
            return false;
        }
        if (TextUtils.isEmpty(specializationInput.getText())) {
            specializationInput.setError("বিশেষজ্ঞ ক্ষেত্র দিন");
            return false;
        }
        if (TextUtils.isEmpty(unionDropdown.getText())) {
            unionDropdown.setError("ইউনিয়ন নির্বাচন করুন");
            return false;
        }
        return true;
    }

    private Bitmap resizeBitmap(Bitmap bitmap, int max) {
        int w = bitmap.getWidth();
        int h = bitmap.getHeight();
        float ratio = (float) w / h;

        if (ratio > 1) {
            w = max;
            h = (int) (w / ratio);
        } else {
            h = max;
            w = (int) (h * ratio);
        }
        return Bitmap.createScaledBitmap(bitmap, w, h, true);
    }

    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 75, baos);
        return "data:image/jpeg;base64," +
                Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP);
    }

    private void submitForm() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.ADD_SPECIALIST_DOCTOR,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    if (response.trim().startsWith("<")) {
                        Toast.makeText(this, "সার্ভার এরর", Toast.LENGTH_LONG).show();
                        return;
                    }

                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success")) {
                            Toast.makeText(this,
                                    json.optString("message"),
                                    Toast.LENGTH_SHORT).show();
                            setResult(RESULT_OK);
                            finish();
                        } else {
                            Toast.makeText(this,
                                    json.optString("message"),
                                    Toast.LENGTH_SHORT).show();
                        }
                    } catch (JSONException e) {
                        Toast.makeText(this, "Response parse error", Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    Toast.makeText(this, "Network error", Toast.LENGTH_LONG).show();
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> p = new HashMap<>();
                SessionManager sm = new SessionManager(AddUnifiedSpecialistDoctorActivity.this);

                p.put("user_id", sm.getId());
                p.put("name", nameInput.getText().toString().trim());
                p.put("qualifications", qualificationsInput.getText().toString().trim());
                p.put("specialization", specializationInput.getText().toString().trim());
                p.put("doctor_type", doctorType);
                p.put("workplace", workplaceInput.getText().toString().trim());
                p.put("chamber", chamberInput.getText().toString().trim());
                p.put("visiting_hours", visitingHoursInput.getText().toString().trim());
                p.put("phone", phoneInput.getText().toString().trim());
                p.put("address", addressInput.getText().toString().trim());
                p.put("union", unionDropdown.getText().toString().trim());

                if (!TextUtils.isEmpty(doctorImageBase64)) {
                    p.put("image", doctorImageBase64);
                }
                return p;
            }

            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    return Response.success(
                            new String(response.data, "UTF-8"),
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response)
                    );
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }
        };

        request.setRetryPolicy(new DefaultRetryPolicy(
                60000,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        ));

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void hideKeyboard() {
        View v = getCurrentFocus();
        if (v != null) {
            InputMethodManager imm =
                    (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) imm.hideSoftInputFromWindow(v.getWindowToken(), 0);
        }
    }
}
