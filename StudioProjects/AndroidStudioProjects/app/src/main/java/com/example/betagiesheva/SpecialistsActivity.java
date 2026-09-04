package com.example.betagiesheva;

import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.card.MaterialCardView;

import java.util.ArrayList;
import java.util.List;

public class SpecialistsActivity extends AppCompatActivity {

    // UI elements from activity_specialists.xml
    private MaterialCardView card1, card2, card3, card4, card5, card6, card7, card8, card9, card10, card11, card12;
    private MaterialCardView customDialogDoctor;
    private ImageView backButton;
    private List<SpecialistType> specialistTypes;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_specialists);

        // Initialize views and data
        initializeViews();
        loadSpecialistTypes();
    }

    private void initializeViews() {
        backButton = findViewById(R.id.back_button);
        customDialogDoctor = findViewById(R.id.custom_dialog_doctor);
        card1 = findViewById(R.id.card1);
        card2 = findViewById(R.id.card2);
        card3 = findViewById(R.id.card3);
        card4 = findViewById(R.id.card4);
        card5 = findViewById(R.id.card5);
        card6 = findViewById(R.id.card6);
        card7 = findViewById(R.id.card7);
        card8 = findViewById(R.id.card8);
        card9 = findViewById(R.id.card9);
        card10 = findViewById(R.id.card10);
        card11 = findViewById(R.id.card11);
        card12 = findViewById(R.id.card12);

        backButton.setOnClickListener(v -> finish());
        customDialogDoctor.setOnClickListener(v -> showCustomDialog());//
    }
    public void showCustomDialog() {
        final Dialog dialog = new Dialog(this);
        dialog.setContentView(R.layout.custom_dialog_doctor);
        dialog.setCancelable(true);
        Button closeButton = (Button) dialog.findViewById(R.id.btn_close);
        closeButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.Specialists_Activity.2
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                dialog.dismiss();
            }
        });
        dialog.show();
    }
    private void loadSpecialistTypes() {
        specialistTypes = getSpecialistTypes();

        // Wire click listeners for each static card to open the doctor list for that specialist
        // The order matches the XML layout: গাইনি, দন্ত, অর্থপেডিক, শিশু, মনোরোগ, চক্ষু, নাক কান গলা, কিডনি, মেডিসিন, নিউরোলজিস্ট, চর্ম রোগ, হৃদরোগ
        if (specialistTypes.size() >= 1) card1.setOnClickListener(v -> openSpecialist(specialistTypes.get(0)));
        if (specialistTypes.size() >= 2) card2.setOnClickListener(v -> openSpecialist(specialistTypes.get(1)));
        if (specialistTypes.size() >= 3) card3.setOnClickListener(v -> openSpecialist(specialistTypes.get(2)));
        if (specialistTypes.size() >= 4) card4.setOnClickListener(v -> openSpecialist(specialistTypes.get(3)));
        if (specialistTypes.size() >= 5) card5.setOnClickListener(v -> openSpecialist(specialistTypes.get(4)));
        if (specialistTypes.size() >= 6) card6.setOnClickListener(v -> openSpecialist(specialistTypes.get(5)));
        if (specialistTypes.size() >= 7) card7.setOnClickListener(v -> openSpecialist(specialistTypes.get(6)));
        if (specialistTypes.size() >= 8) card8.setOnClickListener(v -> openSpecialist(specialistTypes.get(7)));
        if (specialistTypes.size() >= 9) card9.setOnClickListener(v -> openSpecialist(specialistTypes.get(8)));
        if (specialistTypes.size() >= 10) card10.setOnClickListener(v -> openSpecialist(specialistTypes.get(9)));
        if (specialistTypes.size() >= 11) card11.setOnClickListener(v -> openSpecialist(specialistTypes.get(10)));
        if (specialistTypes.size() >= 12) card12.setOnClickListener(v -> openSpecialist(specialistTypes.get(11)));
    }

    private void openSpecialist(SpecialistType type) {
        Intent intent = new Intent(SpecialistsActivity.this, UnifiedSpecialistDoctorActivity.class);
        intent.putExtra("specialistType", type.id);
        intent.putExtra("displayName", type.name);
        startActivity(intent);
    }

    private List<SpecialistType> getSpecialistTypes() {
        List<SpecialistType> types = new ArrayList<>();

        // Order matches the XML layout cards
        types.add(new SpecialistType("gynecology", "গাইনি বিশেষজ্ঞ", R.drawable.gynecologist));
        types.add(new SpecialistType("dental", "দন্ত চিকিৎসক", R.drawable.dentist));
        types.add(new SpecialistType("orthopedics", "অর্থপেডিক বিশেষজ্ঞ", R.drawable.orthopedic));
        types.add(new SpecialistType("pediatrics", "শিশু বিশেষজ্ঞ", R.drawable.pre));
        types.add(new SpecialistType("psychiatry", "মনোরোগ বিশেষজ্ঞ", R.drawable.psy));
        types.add(new SpecialistType("eye", "চক্ষু বিশেষজ্ঞ", R.drawable.ophthalmologist));
        types.add(new SpecialistType("ent", "নাক কান গলা", R.drawable.nak));
        types.add(new SpecialistType("kidney", "কিডনি রোগ", R.drawable.kidney));
        types.add(new SpecialistType("medicine", "মেডিসিন বিশেষজ্ঞ", R.drawable.medicine));
        types.add(new SpecialistType("neurology", "নিউরোলজিস্ট", R.drawable.neurologist));
        types.add(new SpecialistType("skin", "চর্ম রোগ বিশেষজ্ঞ", R.drawable.dermatologist));
        types.add(new SpecialistType("cardiology", "হৃদরোগ বিশেষজ্ঞ", R.drawable.cardiologist));

        return types;
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }

    private static class SpecialistType {
        String id;
        String name;
        int iconResId;

        SpecialistType(String id, String name, int iconResId) {
            this.id = id;
            this.name = name;
            this.iconResId = iconResId;
        }
    }
}