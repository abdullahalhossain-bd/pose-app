package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.example.betagiesheva.Model.Complaint;

public class InformationSubmitActivity extends AppCompatActivity {

    public static final String EXTRA_COMPLAINT = "extra_complaint";
    public static final String EXTRA_RESULT_MESSAGE = "extra_result_message";

    private TextView valueType;
    private TextView valueTitle;
    private TextView valueDescription;
    private TextView valueLocation;
    private TextView valueDepartment;
    private TextView valuePriority;
    private TextView valueContact;
    private TextView valueEmail;
    private TextView valueName;
    private TextView valueDate;
    private ImageView attachedImage;
    private ProgressBar progress;
    private CardView confirmSubmitButton;
    private CardView editBackButton;

    private Complaint complaint;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_information_submit);

        valueType = findViewById(R.id.valueType);
        valueTitle = findViewById(R.id.valueTitle);
        valueDescription = findViewById(R.id.valueDescription);
        valueLocation = findViewById(R.id.valueLocation);
        valueDepartment = findViewById(R.id.valueDepartment);
        valuePriority = findViewById(R.id.valuePriority);
        valueContact = findViewById(R.id.valueContact);
        valueEmail = findViewById(R.id.valueEmail);
        valueName = findViewById(R.id.valueName);
        valueDate = findViewById(R.id.valueDate);
        attachedImage = findViewById(R.id.attachedImage);
        progress = findViewById(R.id.progress);
        confirmSubmitButton = findViewById(R.id.confirmSubmitButton);
        editBackButton = findViewById(R.id.editBackButton);

        complaint = (Complaint) getIntent().getSerializableExtra(EXTRA_COMPLAINT);
        if (complaint == null) {
            Toast.makeText(this, "তথ্য পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
            setResult(RESULT_CANCELED);
            finish();
            return;
        }

        bindValues(complaint);

        editBackButton.setOnClickListener(v -> {
            setResult(RESULT_CANCELED);
            finish();
        });

        confirmSubmitButton.setOnClickListener(v -> doSubmit());
    }

    private void bindValues(Complaint c) {
        valueType.setText(safe(c.getType()));
        valueTitle.setText(safe(c.getTitle()));
        valueDescription.setText(safe(c.getDetails()));
        valueLocation.setText(safe(c.getLocation()));
        valueDepartment.setText(safe(c.getDepartment()));
        valuePriority.setText(safe(c.getPriority()));
        valueContact.setText(safe(c.getContactNumber()));
        valueEmail.setText(safe(c.getEmail()));
        valueName.setText(safe(c.getComplainantName()));
        valueDate.setText(safe(c.getComplaintDate()));

        if (!TextUtils.isEmpty(c.getImageUrl())) {
            try {
                Uri uri = Uri.parse(c.getImageUrl());
                attachedImage.setImageURI(uri);
                attachedImage.setVisibility(android.view.View.VISIBLE);
            } catch (Exception ignored) {
                attachedImage.setVisibility(android.view.View.GONE);
            }
        } else {
            attachedImage.setVisibility(android.view.View.GONE);
        }
    }

    private String safe(String v) {
        return TextUtils.isEmpty(v) ? "-" : v;
    }

    private void doSubmit() {
        progress.setVisibility(android.view.View.VISIBLE);
        confirmSubmitButton.setEnabled(false);
        editBackButton.setEnabled(false);

        // TODO: Here you can call your API/Firestore to submit the complaint/information.
        // For now we simulate a quick submit.
        new Handler().postDelayed(() -> {
            progress.setVisibility(android.view.View.GONE);

            Intent data = new Intent();
            data.putExtra(EXTRA_RESULT_MESSAGE, "আপনার তথ্য সফলভাবে সাবমিট হয়েছে");
            setResult(RESULT_OK, data);
            finish();
        }, 1200);
    }
}

