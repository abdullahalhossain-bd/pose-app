package com.example.betagiesheva;

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
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Model.Clinic;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class AddClinicActivity extends AppCompatActivity {

    private static final String TAG = "AddClinicActivity";

    private CircleImageView clinicImage;
    private String clinicImageBase64 = "";

    private TextInputEditText clinicName, clinicAddress, placeName, clinicPhone,
            complaintPhone, clinicEmail, establishmentDate, founderName,
            transportInfo, operatingHours;

    private AutoCompleteTextView unionDropdown;
    private LinearLayout servicesContainer;
    private CardView submitButton;
    private CardView deleteButton;
    private ProgressBar progressBar;
    private TextView addServiceButton;
    private SessionManager sessionManager;
    private boolean isAdmin = false;

    private Clinic editingClinic;
    private boolean isEditMode = false;

    private final List<ServiceRow> serviceRows = new ArrayList<>();

    private final String[] unionNames = {
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
        setContentView(R.layout.activity_add_clinic);

        bindViews();
        setupUnionDropdown();
        setupActions();
        registerDefaultServiceRow();
        checkForEditMode();
        setupAdminControls();
    }

    // ================= IMAGE PICKER =================

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
                                clinicImage.setImageBitmap(bitmap);
                                clinicImageBase64 = bitmapToBase64(bitmap);
                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        }
                    }
            );

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

    // ================= INIT =================

    private void bindViews() {
        clinicImage = findViewById(R.id.clinicImage);
        clinicName = findViewById(R.id.clinicName);
        clinicAddress = findViewById(R.id.clinicAddress);
        placeName = findViewById(R.id.placeName);
        clinicPhone = findViewById(R.id.clinicPhone);
        complaintPhone = findViewById(R.id.complaintPhone);
        clinicEmail = findViewById(R.id.clinicEmail);
        establishmentDate = findViewById(R.id.establishmentDate);
        founderName = findViewById(R.id.founderName);
        transportInfo = findViewById(R.id.transportInfo);
        operatingHours = findViewById(R.id.operatingHours);
        unionDropdown = findViewById(R.id.unionDropdown);
        servicesContainer = findViewById(R.id.servicesContainer);
        submitButton = findViewById(R.id.submitButton);
        deleteButton = findViewById(R.id.deleteButton);
        progressBar = findViewById(R.id.progress);
        addServiceButton = findViewById(R.id.addServiceButton);
    }

    private void setupUnionDropdown() {
        unionDropdown.setAdapter(new ArrayAdapter<>(
                this,
                android.R.layout.simple_dropdown_item_1line,
                unionNames
        ));
    }

    private void setupActions() {
        clinicImage.setOnClickListener(v -> openGallery());

        addServiceButton.setOnClickListener(v -> addServiceRow("", ""));

        submitButton.setOnClickListener(v -> {
            if (validate()) submit();
        });

        if (deleteButton != null) {
            deleteButton.setOnClickListener(v -> confirmDelete());
        }
    }

    // ================= EDIT MODE =================

    private void checkForEditMode() {
        editingClinic = getIntent().getParcelableExtra("clinic_data");
        if (editingClinic == null) return;

        isEditMode = true;
        clinicName.setText(editingClinic.getName());
        clinicAddress.setText(editingClinic.getAddress());
        placeName.setText(editingClinic.getPlaceName());
        clinicPhone.setText(editingClinic.getPhoneNumber());
        complaintPhone.setText(editingClinic.getComplaintPhoneNumber());
        clinicEmail.setText(editingClinic.getEmail());
        establishmentDate.setText(editingClinic.getEstablishDate());
        founderName.setText(editingClinic.getFounderName());
        transportInfo.setText(editingClinic.getTransportInfo());
        operatingHours.setText(editingClinic.getOperatingHours());
        unionDropdown.setText(editingClinic.getUnion(), false);

        if (editingClinic.getServices() != null) {
            servicesContainer.removeAllViews();
            serviceRows.clear();
            for (Map.Entry<String, Object> e : editingClinic.getServices().entrySet()) {
                addServiceRow(e.getKey(), String.valueOf(e.getValue()));
            }
        }
    }

    private void setupAdminControls() {
        sessionManager = new SessionManager(this);
        isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());

        if (isEditMode) {
            if (isAdmin) {
                if (deleteButton != null) deleteButton.setVisibility(View.VISIBLE);
                submitButton.setVisibility(View.VISIBLE);
            } else {
                submitButton.setVisibility(View.GONE);
                if (deleteButton != null) deleteButton.setVisibility(View.GONE);
            }
        }
    }

    // ================= SERVICES =================

    private void registerDefaultServiceRow() {
        if (servicesContainer.getChildCount() == 0) {
            addServiceRow("", "");
        }
    }

    private void addServiceRow(String name, String fee) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);

        TextInputLayout nameLayout = createInputLayout("সেবার নাম", 2f);
        TextInputEditText nameInput = new TextInputEditText(this);
        nameInput.setText(name);
        nameLayout.addView(nameInput);

        TextInputLayout feeLayout = createInputLayout("ফি (৳)", 1f);
        TextInputEditText feeInput = new TextInputEditText(this);
        feeInput.setInputType(android.text.InputType.TYPE_CLASS_NUMBER |
                android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL);
        feeInput.setText(fee);
        feeLayout.addView(feeInput);

        ImageButton removeBtn = new ImageButton(this);
        removeBtn.setImageResource(R.drawable.ic_menu_remove);
        removeBtn.setBackground(null);
        removeBtn.setOnClickListener(v -> removeServiceRow(row));

        row.addView(nameLayout);
        row.addView(feeLayout);
        row.addView(removeBtn);

        servicesContainer.addView(row);
        serviceRows.add(new ServiceRow(row, nameInput, feeInput));
    }

    private TextInputLayout createInputLayout(String hint, float weight) {
        TextInputLayout layout = new TextInputLayout(this);
        layout.setHint(hint);
        layout.setLayoutParams(new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, weight
        ));
        return layout;
    }

    private void removeServiceRow(LinearLayout row) {
        if (serviceRows.size() <= 1) {
            toast("কমপক্ষে একটি সেবা রাখতে হবে");
            return;
        }

        servicesContainer.removeView(row);
        Iterator<ServiceRow> it = serviceRows.iterator();
        while (it.hasNext()) {
            if (it.next().row == row) {
                it.remove();
                break;
            }
        }
    }

    // ================= VALIDATION =================

    private boolean validate() {
        if (isEmpty(clinicName, "ক্লিনিক এর নাম দিন")) return false;
        if (isEmpty(clinicAddress, "ঠিকানা দিন")) return false;
        if (unionDropdown.getText().toString().trim().isEmpty()) {
            toast("ইউনিয়ন নির্বাচন করুন");
            return false;
        }

        for (ServiceRow r : serviceRows) {
            if (!r.name().isEmpty() && !r.fee().isEmpty()) return true;
        }

        toast("কমপক্ষে একটি সেবা যোগ করুন");
        return false;
    }

    private boolean isEmpty(TextInputEditText e, String msg) {
        if (e.getText() == null || e.getText().toString().trim().isEmpty()) {
            toast(msg);
            return true;
        }
        return false;
    }

    // ================= SUBMIT =================

    // ================= IMPROVED SUBMIT METHOD =================
    private void submit() {
        hideKeyboard();
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);

        // Build services JSON
        JSONArray services = new JSONArray();
        for (ServiceRow r : serviceRows) {
            if (r.name().isEmpty() || r.fee().isEmpty()) continue;
            try {
                JSONObject o = new JSONObject();
                o.put("test_name", r.name());
                o.put("fee", Double.parseDouble(r.fee()));
                services.put(o);
            } catch (JSONException | NumberFormatException e) {
                Log.e(TAG, "Error creating service JSON", e);
            }
        }

        // Log the services JSON for debugging
        Log.d(TAG, "Services JSON: " + services.toString());

        String url = isEditMode ? Config.UPDATE_CLINIC : Config.ADD_CLINIC;

        AuthRequest req = new AuthRequest(
                Request.Method.POST,
                url,
                res -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);
                    Log.d(TAG, "Success response: " + res);
                    toast("সফল হয়েছে");
                    finish();
                },
                err -> {
                    progressBar.setVisibility(View.GONE);
                    submitButton.setEnabled(true);

                    // Detailed error logging
                    String errorMsg = "নেটওয়ার্ক সমস্যা";
                    if (err.networkResponse != null) {
                        int statusCode = err.networkResponse.statusCode;
                        String responseBody = new String(err.networkResponse.data);
                        Log.e(TAG, "Error Status Code: " + statusCode);
                        Log.e(TAG, "Error Response: " + responseBody);
                        errorMsg = "Error " + statusCode + ": " + responseBody;
                    }
                    toast(errorMsg);
                    Log.e(TAG, "error", err);
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> p = new HashMap<>();

                if (isEditMode && editingClinic != null) {
                    p.put("id", editingClinic.getId());
                }

                String nameValue = clinicName.getText() != null ? clinicName.getText().toString().trim() : "";
                String addressValue = clinicAddress.getText() != null ? clinicAddress.getText().toString().trim() : "";

                p.put("name", nameValue);
                p.put("address", addressValue);
                p.put("place_name", placeName.getText() != null ? placeName.getText().toString().trim() : "");
                p.put("phone_number", clinicPhone.getText() != null ? clinicPhone.getText().toString().trim() : "");
                p.put("complaint_phone_number", complaintPhone.getText() != null ? complaintPhone.getText().toString().trim() : "");
                p.put("email", clinicEmail.getText() != null ? clinicEmail.getText().toString().trim() : "");
                p.put("establish_date", establishmentDate.getText() != null ? establishmentDate.getText().toString().trim() : "");
                p.put("founder_name", founderName.getText() != null ? founderName.getText().toString().trim() : "");
                p.put("transport_info", transportInfo.getText() != null ? transportInfo.getText().toString().trim() : "");
                p.put("operating_hours", operatingHours.getText() != null ? operatingHours.getText().toString().trim() : "");
                p.put("union_name", unionDropdown.getText() != null ? unionDropdown.getText().toString().trim() : "");
                p.put("services", services.toString());

                if (!clinicImageBase64.isEmpty()) {
                    p.put("img", clinicImageBase64);
                }

                // Log all parameters for debugging
                Log.d(TAG, "=== Request Parameters ===");
                for (Map.Entry<String, String> entry : p.entrySet()) {
                    if (entry.getKey().equals("img")) {
                        Log.d(TAG, entry.getKey() + ": [base64 image data length=" + entry.getValue().length() + "]");
                    } else {
                        Log.d(TAG, entry.getKey() + ": " + entry.getValue());
                    }
                }
                Log.d(TAG, "========================");

                return p;
            }
        };

        req.setRetryPolicy(new DefaultRetryPolicy(30000, 2, 1));
        Config.getInstance(this).addToRequestQueue(req);
    }

    // ================= DELETE =================
    private void confirmDelete() {
        if (editingClinic == null) return;

        new AlertDialog.Builder(this)
                .setTitle("ডিলিট নিশ্চিত করুন")
                .setMessage("এই ক্লিনিকটি ডিলিট করতে চান?")
                .setPositiveButton("হ্যাঁ", (d, w) -> deleteClinic())
                .setNegativeButton("না", null)
                .show();
    }

    private void deleteClinic() {
        progressBar.setVisibility(View.VISIBLE);
        submitButton.setEnabled(false);
        if (deleteButton != null) deleteButton.setEnabled(false);

        AuthRequest req = new AuthRequest(
                Request.Method.POST,
                Config.DELETE_CLINIC,
                res -> {
                    progressBar.setVisibility(View.GONE);
                    toast("ডিলিট হয়েছে");
                    finish();
                },
                err -> {
                    progressBar.setVisibility(View.GONE);
                    if (deleteButton != null) deleteButton.setEnabled(true);
                    submitButton.setEnabled(true);
                    toast("ডিলিট ব্যর্থ");
                    Log.e(TAG, "delete error", err);
                },
                this
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> p = new HashMap<>();
                p.put("id", editingClinic.getId());
                return p;
            }
        };

        req.setRetryPolicy(new DefaultRetryPolicy(30000, 2, 1));
        Config.getInstance(this).addToRequestQueue(req);
    }

    // ================= UTILS =================

    private void hideKeyboard() {
        View v = getCurrentFocus();
        if (v != null) {
            ((InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE))
                    .hideSoftInputFromWindow(v.getWindowToken(), 0);
        }
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
    }

    // ================= MODEL =================

    private static class ServiceRow {
        LinearLayout row;
        TextInputEditText name, fee;

        ServiceRow(LinearLayout r, TextInputEditText n, TextInputEditText f) {
            row = r;
            name = n;
            fee = f;
        }

        String name() { return name.getText().toString().trim(); }
        String fee() { return fee.getText().toString().trim(); }
    }
}
