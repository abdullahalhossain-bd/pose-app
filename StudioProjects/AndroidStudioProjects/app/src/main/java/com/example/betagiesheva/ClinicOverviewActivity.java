package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.example.betagiesheva.Model.Clinic;

import java.util.List;
import java.util.Map;

public class ClinicOverviewActivity extends AppCompatActivity {

    private TextView clinicAddress, clinicNameTextView, email, establishmentDate,
            founderName, phone, timing, transportInfo, unionTextView;
    private ImageView clinicImage;
    private Button complainButton, serialButton, viewTestsFeesButton;
    private Clinic clinic;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_clinic_overview);

        initializeUIComponents();
        setupClickListeners();

        clinic = getIntent().getParcelableExtra("clinic");
        if (clinic == null) {
            Toast.makeText(this, "Clinic data is missing.", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        populateClinicDetails(clinic);
    }

    private void initializeUIComponents() {
        clinicImage = findViewById(R.id.clinic_image);
        clinicNameTextView = findViewById(R.id.clinic_name);
        clinicAddress = findViewById(R.id.address);
        transportInfo = findViewById(R.id.transport_info);
        timing = findViewById(R.id.time);
        phone = findViewById(R.id.phone);
        email = findViewById(R.id.email);
        establishmentDate = findViewById(R.id.establishment_date);
        founderName = findViewById(R.id.founder_name);
        unionTextView = findViewById(R.id.union_name); // Added union TextView
        viewTestsFeesButton = findViewById(R.id.test);
        complainButton = findViewById(R.id.complain);
        serialButton = findViewById(R.id.serial);

        ImageButton backButton = findViewById(R.id.backIcon);
        backButton.setOnClickListener(v -> finish());
    }

    private void setupClickListeners() {
        serialButton.setOnClickListener(v -> {
            String phoneNumber = clinic.getPhoneNumber();
            if (phoneNumber != null && !phoneNumber.isEmpty()) {
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + phoneNumber)));
            } else {
                Toast.makeText(this, "Phone number not available.", Toast.LENGTH_SHORT).show();
            }
        });

        complainButton.setOnClickListener(v -> {
            String complaintPhoneNumber = clinic.getComplaintPhoneNumber();
            if (complaintPhoneNumber != null && !complaintPhoneNumber.isEmpty()) {
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + complaintPhoneNumber)));
            } else {
                Toast.makeText(this, "Complaint number not available.", Toast.LENGTH_SHORT).show();
            }
        });

        viewTestsFeesButton.setOnClickListener(v -> showClinicServiceDialog());
    }

    private void populateClinicDetails(Clinic clinic) {
        clinicNameTextView.setText(getValue(clinic.getName()));
        clinicAddress.setText(getValue(clinic.getAddress()));
        founderName.setText(getValue(clinic.getFounderName()));
        transportInfo.setText(getValue(clinic.getTransportInfo()));
        timing.setText(getValue(clinic.getOperatingHours()));
        establishmentDate.setText(getValue(clinic.getEstablishDate()));
        email.setText(getValue(clinic.getEmail()));
        phone.setText(getValue(clinic.getPhoneNumber()));

        // Display union information
        if (unionTextView != null) {
            unionTextView.setText(getValue(clinic.getUnion()));
        }

        if (clinic.getImg() != null && !clinic.getImg().isEmpty()) {
            Glide.with(this)
                    .load(clinic.getImg())
                    .diskCacheStrategy(DiskCacheStrategy.ALL)
                    .into(clinicImage);
        } else {
            clinicImage.setImageResource(R.drawable.ic_clinic);
        }
    }

    private String getValue(String value) {
        return value != null && !value.isEmpty() ? value : "N/A";
    }

    private void showClinicServiceDialog() {
        LayoutInflater inflater = LayoutInflater.from(this);
        View dialogView = inflater.inflate(R.layout.custom_dialog_clinic_service, null);

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setView(dialogView);

        AlertDialog dialog = builder.create();

        TableLayout tableLayout = dialogView.findViewById(R.id.services_table);
        LinearLayout loadingContainer = dialogView.findViewById(R.id.loading_container);

        Button btnClose = dialogView.findViewById(R.id.btn_close_services);
        Button btnCancel = dialogView.findViewById(R.id.btn_cancel);

        // Show loading if needed
        loadingContainer.setVisibility(View.GONE);

        // Get services map
        if (clinic.getServices() != null && !clinic.getServices().isEmpty()) {

            for (Map.Entry<String, Object> entry : clinic.getServices().entrySet()) {

                TableRow row = new TableRow(this);
                row.setPadding(8, 8, 8, 8);

                TextView testName = new TextView(this);
                testName.setText(entry.getKey());
                testName.setTextSize(16f);
                testName.setPadding(8, 8, 8, 8);
                testName.setLayoutParams(
                        new TableRow.LayoutParams(0, TableRow.LayoutParams.WRAP_CONTENT, 1.5f)
                );

                TextView fee = new TextView(this);
                fee.setText("৳ " + entry.getValue());
                fee.setTextSize(16f);
                fee.setGravity(View.TEXT_ALIGNMENT_VIEW_END);
                fee.setPadding(8, 8, 8, 8);
                fee.setLayoutParams(
                        new TableRow.LayoutParams(0, TableRow.LayoutParams.WRAP_CONTENT, 1f)
                );

                row.addView(testName);
                row.addView(fee);

                tableLayout.addView(row);
            }

        } else {
            // No service available
            TableRow row = new TableRow(this);

            TextView noData = new TextView(this);
            noData.setText("কোন সেবা তথ্য পাওয়া যায়নি");
            noData.setTextSize(16f);
            noData.setPadding(12, 12, 12, 12);

            row.addView(noData);
            tableLayout.addView(row);
        }

        btnClose.setOnClickListener(v -> dialog.dismiss());
        btnCancel.setOnClickListener(v -> dialog.dismiss());

        dialog.show();
    }

}