package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.cardview.widget.CardView;

public class SimActivity extends AppCompatActivity {
    private CardView card1;
    private CardView card2;
    private CardView card3;
    private CardView card4;
    private CardView card5;
    private CardView card6;
    private CardView card7;
    private CardView card8;
    private CardView card9;
    private Toolbar toolbar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sim);

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }

        card1 = findViewById(R.id.card1);
        card2 = findViewById(R.id.card2);
        card3 = findViewById(R.id.card3);
        card4 = findViewById(R.id.card4);
        card5 = findViewById(R.id.card5);
        card6 = findViewById(R.id.card6);
        card7 = findViewById(R.id.card7);
        card8 = findViewById(R.id.card8);
        card9 = findViewById(R.id.card9);

        setupCardClickListeners();
    }

    private void setupCardClickListeners() {
        card1.setOnClickListener(v -> openSimDetailActivity("gp", "গ্রামীনফোন সিম"));
        card2.setOnClickListener(v -> openSimDetailActivity("banglalink", "বাংলালিংক সিম"));
        card3.setOnClickListener(v -> openSimDetailActivity("teletalk", "টেলিটক সিম"));
        card4.setOnClickListener(v -> openSimDetailActivity("robi", "রবি সিম"));
        card5.setOnClickListener(v -> openSimDetailActivity("airtel", "এয়ারটেল সিম"));
        card6.setOnClickListener(v -> openSimDetailActivity("helpcenter", "হেল্প সেন্টার"));
        card7.setOnClickListener(v -> dialUssdCode("*167#"));
        card8.setOnClickListener(v -> dialUssdCode("*247#"));
        card9.setOnClickListener(v -> dialUssdCode("*322#"));
    }

    private void openSimDetailActivity(String simType, String displayName) {
        Intent intent = new Intent(this, SimDetailActivity.class);
        intent.putExtra("simType", simType);
        intent.putExtra("displayName", displayName);
        startActivity(intent);
    }

    private void dialUssdCode(String code) {
        Intent intent = new Intent(Intent.ACTION_DIAL);
        intent.setData(Uri.parse("tel:" + code));
        startActivity(intent);
    }
}