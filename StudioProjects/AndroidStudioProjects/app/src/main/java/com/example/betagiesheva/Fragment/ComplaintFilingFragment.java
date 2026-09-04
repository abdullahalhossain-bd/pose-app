package com.example.betagiesheva.Fragment;

import android.app.Activity;
import android.app.DatePickerDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.DatePicker;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.R;
import com.example.betagiesheva.Model.Complaint;
import com.example.betagiesheva.helper.AuthRequest;
import com.google.android.material.textfield.TextInputEditText;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class ComplaintFilingFragment extends Fragment {

    private AutoCompleteTextView complaintTypeAutoComplete;
    private AutoCompleteTextView departmentAutoComplete;
    private AutoCompleteTextView priorityAutoComplete;
    private TextInputEditText complaintTitleEditText;
    private TextInputEditText complaintDetailsEditText;
    private TextInputEditText locationEditText;
    private TextInputEditText contactNumberEditText;
    private TextInputEditText emailEditText;
    private TextInputEditText complainantNameEditText;
    private TextInputEditText complaintDateEditText;
    private ImageView attachedPhotoPreview;
    private CardView attachPhotoButton;
    private CardView submitButton;
    private CardView clearButton;
    private ProgressBar progressBar;
    private Uri selectedImageUri;
    /** Most recently filed complaint — kept around so the Fragment can submit it to the
     *  server after the user confirms in InformationSubmitActivity. */
    private Complaint pendingComplaint;

    private static final String ARG_USER_ID = "user_id";
    private static final int PICK_IMAGE_REQUEST = 1;
    private static final int REQUEST_INFORMATION_SUBMIT = 2;

    public static ComplaintFilingFragment newInstance(String userId) {
        ComplaintFilingFragment fragment = new ComplaintFilingFragment();
        Bundle args = new Bundle();
        args.putString(ARG_USER_ID, userId);
        fragment.setArguments(args);
        return fragment;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_complaint_filing, container, false);

        // Initialize all views
        initializeViews(view);

        // Setup dropdown adapters
        setupDropdownAdapters();

        // Setup button listeners
        setupButtonListeners();

        // Set current date
        setCurrentDate();

        return view;
    }

    private void initializeViews(View view) {
        complaintTypeAutoComplete = view.findViewById(R.id.complaintTypeAutoComplete);
        departmentAutoComplete = view.findViewById(R.id.departmentAutoComplete);
        priorityAutoComplete = view.findViewById(R.id.priorityAutoComplete);
        complaintTitleEditText = view.findViewById(R.id.complaintTitle);
        complaintDetailsEditText = view.findViewById(R.id.complaintDetailsEditText);
        locationEditText = view.findViewById(R.id.locationEditText);
        contactNumberEditText = view.findViewById(R.id.contactNumberEditText);
        emailEditText = view.findViewById(R.id.emailEditText);
        complainantNameEditText = view.findViewById(R.id.complainantNameEditText);
        complaintDateEditText = view.findViewById(R.id.complaintDateEditText);
        attachedPhotoPreview = view.findViewById(R.id.attachedPhotoPreview);
        attachPhotoButton = view.findViewById(R.id.attachPhotoButton);
        submitButton = view.findViewById(R.id.submitButton);
        clearButton = view.findViewById(R.id.clearButton);
        progressBar = view.findViewById(R.id.progress);
    }

    private void setupDropdownAdapters() {
        // Complaint Type Dropdown
        List<String> complaintTypes = new ArrayList<>();
        complaintTypes.add("দুর্নীতি");
        complaintTypes.add("সেবা বঞ্চনা");
        complaintTypes.add("অনিয়ম");
        complaintTypes.add("অপব্যবহার");
        complaintTypes.add("অন্যান্য");

        ArrayAdapter<String> complaintTypeAdapter = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_dropdown_item_1line,
                complaintTypes
        );
        complaintTypeAutoComplete.setAdapter(complaintTypeAdapter);

        // Department Dropdown
        List<String> departments = new ArrayList<>();
        departments.add("স্থানীয় সরকার");
        departments.add("শিক্ষা বিভাগ");
        departments.add("স্বাস্থ্য বিভাগ");
        departments.add("পুলিশ বিভাগ");
        departments.add("অন্যান্য");

        ArrayAdapter<String> departmentAdapter = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_dropdown_item_1line,
                departments
        );
        departmentAutoComplete.setAdapter(departmentAdapter);

        // Priority Dropdown
        List<String> priorities = new ArrayList<>();
        priorities.add("জরুরি");
        priorities.add("উচ্চ");
        priorities.add("মাঝারি");
        priorities.add("নিম্ন");

        ArrayAdapter<String> priorityAdapter = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_dropdown_item_1line,
                priorities
        );
        priorityAutoComplete.setAdapter(priorityAdapter);
    }

    private void setupButtonListeners() {
        attachPhotoButton.setOnClickListener(v -> openGallery());
        submitButton.setOnClickListener(v -> submitComplaint());
        clearButton.setOnClickListener(v -> clearForm());
        complaintDateEditText.setOnClickListener(v -> openDatePicker());
    }

    private void setCurrentDate() {
        Calendar calendar = Calendar.getInstance();
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
        complaintDateEditText.setText(dateFormat.format(calendar.getTime()));
    }

    private void openDatePicker() {
        Calendar calendar = Calendar.getInstance();
        DatePickerDialog datePickerDialog = new DatePickerDialog(
                requireContext(),
                (view, year, month, dayOfMonth) -> {
                    Calendar selectedDate = Calendar.getInstance();
                    selectedDate.set(year, month, dayOfMonth);
                    SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());
                    complaintDateEditText.setText(dateFormat.format(selectedDate.getTime()));
                },
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),
                calendar.get(Calendar.DAY_OF_MONTH)
        );
        datePickerDialog.show();
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == Activity.RESULT_OK && data != null && data.getData() != null) {
            selectedImageUri = data.getData();
            attachedPhotoPreview.setImageURI(selectedImageUri);
            attachedPhotoPreview.setVisibility(View.VISIBLE);
            Toast.makeText(getContext(), "ছবি সংযুক্ত হয়েছে", Toast.LENGTH_SHORT).show();
        } else if (requestCode == REQUEST_INFORMATION_SUBMIT) {
            if (resultCode == Activity.RESULT_OK) {
                // User confirmed in InformationSubmitActivity — now actually
                // submit to the server.
                submitComplaintToServer(pendingComplaint);
            }
        }
    }

    private void submitComplaint() {
        // Validate all required fields
        if (!validateForm()) {
            return;
        }

        // Show progress bar
        progressBar.setVisibility(View.VISIBLE);

        String userId = getArguments() != null ? getArguments().getString(ARG_USER_ID) : null;
        String complaintType = complaintTypeAutoComplete.getText().toString().trim();
        String title = complaintTitleEditText.getText().toString().trim();
        String details = complaintDetailsEditText.getText().toString().trim();
        String location = locationEditText.getText().toString().trim();
        String department = departmentAutoComplete.getText().toString().trim();
        String priority = priorityAutoComplete.getText().toString().trim();
        String contactNumber = contactNumberEditText.getText().toString().trim();
        String email = emailEditText.getText().toString().trim();
        String complainantName = complainantNameEditText.getText().toString().trim();
        String complaintDate = complaintDateEditText.getText().toString().trim();

        Complaint complaint = new Complaint(
                userId,
                complaintType,
                title,
                details,
                location,
                department,
                priority,
                contactNumber,
                email,
                complainantName,
                complaintDate,
                selectedImageUri != null ? selectedImageUri.toString() : null
        );
        this.pendingComplaint = complaint;

        // Open confirmation screen (InformationSubmitActivity). The actual server
        // submission happens in onActivityResult() once the user confirms.
        progressBar.setVisibility(View.GONE);
        Intent intent = new Intent(requireContext(), com.example.betagiesheva.InformationSubmitActivity.class);
        intent.putExtra(com.example.betagiesheva.InformationSubmitActivity.EXTRA_COMPLAINT, complaint);
        startActivityForResult(intent, REQUEST_INFORMATION_SUBMIT);
    }

    /**
     * Submits the complaint to {@code Config.SUBMIT_COMPLAINT_URL} using AuthRequest
     * (complaints require login → JWT in Authorization header).
     *
     * NOTE: server's submit_complaint.php endpoint is created in Phase 6. Until then
     * every request will fail (typically 404 VolleyError) — we show the configured
     * Bengali error toast and DO NOT pop the back stack so the user can retry.
     */
    private void submitComplaintToServer(Complaint complaint) {
        if (complaint == null) return;
        progressBar.setVisibility(View.VISIBLE);

        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.SUBMIT_COMPLAINT_URL,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    try {
                        JSONObject json = new JSONObject(response);
                        if (json.optBoolean("success", false)) {
                            Toast.makeText(getContext(),
                                    "আপনার অভিযোগটি সফলভাবে দাখিল হয়েছে",
                                    Toast.LENGTH_LONG).show();
                            getParentFragmentManager().popBackStack();
                        } else {
                            Toast.makeText(getContext(),
                                    "অভিযোগ জমা দেওয়া যায়নি। পরে আবার চেষ্টা করুন।",
                                    Toast.LENGTH_LONG).show();
                        }
                    } catch (Exception e) {
                        Toast.makeText(getContext(),
                                "অভিযোগ জমা দেওয়া যায়নি। পরে আবার চেষ্টা করুন।",
                                Toast.LENGTH_LONG).show();
                    }
                },
                error -> {
                    // 404 / VolleyError until Phase 6 wires up submit_complaint.php
                    progressBar.setVisibility(View.GONE);
                    Toast.makeText(getContext(),
                            "অভিযোগ জমা দেওয়া যায়নি। পরে আবার চেষ্টা করুন।",
                            Toast.LENGTH_LONG).show();
                },
                requireContext()
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> params = new HashMap<>();
                params.put("user_id", complaint.getUserId() != null ? complaint.getUserId() : "");
                params.put("complaint_type", complaint.getType());
                params.put("title", complaint.getTitle());
                params.put("details", complaint.getDetails());
                params.put("location", complaint.getLocation());
                params.put("department", complaint.getDepartment());
                params.put("priority", complaint.getPriority());
                params.put("contact_number", complaint.getContactNumber());
                params.put("email", complaint.getEmail());
                params.put("complainant_name", complaint.getComplainantName());
                params.put("complaint_date", complaint.getComplaintDate());
                if (complaint.getImageUrl() != null) {
                    params.put("image_url", complaint.getImageUrl());
                }
                return params;
            }
        };

        RequestQueue queue = Volley.newRequestQueue(requireContext());
        queue.add(request);
    }

    private boolean validateForm() {
        String complaintType = complaintTypeAutoComplete.getText().toString().trim();
        String title = complaintTitleEditText.getText().toString().trim();
        String details = complaintDetailsEditText.getText().toString().trim();
        String location = locationEditText.getText().toString().trim();
        String department = departmentAutoComplete.getText().toString().trim();
        String priority = priorityAutoComplete.getText().toString().trim();
        String contactNumber = contactNumberEditText.getText().toString().trim();
        String email = emailEditText.getText().toString().trim();
        String complainantName = complainantNameEditText.getText().toString().trim();

        if (complaintType.isEmpty()) {
            Toast.makeText(getContext(), "অভিযোগের ধরণ নির্বাচন করুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (title.isEmpty()) {
            Toast.makeText(getContext(), "অভিযোগের শিরোনাম লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (details.isEmpty()) {
            Toast.makeText(getContext(), "বিস্তারিত বর্ণনা লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (location.isEmpty()) {
            Toast.makeText(getContext(), "অবস্থান লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (department.isEmpty()) {
            Toast.makeText(getContext(), "বিভাগ নির্বাচন করুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (priority.isEmpty()) {
            Toast.makeText(getContext(), "অগ্রাধিকার নির্বাচন করুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (contactNumber.isEmpty()) {
            Toast.makeText(getContext(), "যোগাযোগ নম্বর লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (!isValidPhoneNumber(contactNumber)) {
            Toast.makeText(getContext(), "বৈধ ফোন নম্বর লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (email.isEmpty()) {
            Toast.makeText(getContext(), "ইমেইল ঠিকানা লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (!isValidEmail(email)) {
            Toast.makeText(getContext(), "বৈধ ইমেইল ঠিকানা লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (complainantName.isEmpty()) {
            Toast.makeText(getContext(), "অভিযোগকারীর নাম লিখুন", Toast.LENGTH_SHORT).show();
            return false;
        }

        return true;
    }

    private boolean isValidPhoneNumber(String phoneNumber) {
        return phoneNumber.matches("^[0-9]{10,11}$");
    }

    private boolean isValidEmail(String email) {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches();
    }

    private void clearForm() {
        complaintTypeAutoComplete.setText("");
        complaintTitleEditText.setText("");
        complaintDetailsEditText.setText("");
        locationEditText.setText("");
        departmentAutoComplete.setText("");
        priorityAutoComplete.setText("");
        contactNumberEditText.setText("");
        emailEditText.setText("");
        complainantNameEditText.setText("");
        attachedPhotoPreview.setVisibility(View.GONE);
        selectedImageUri = null;
        setCurrentDate();
        Toast.makeText(getContext(), "ফর্ম পরিষ্কার করা হয়েছে", Toast.LENGTH_SHORT).show();
    }
}
