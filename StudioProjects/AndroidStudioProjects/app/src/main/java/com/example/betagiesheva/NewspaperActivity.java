package com.example.betagiesheva;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.card.MaterialCardView;

public class NewspaperActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_newspaper);

        ImageView backButton = findViewById(R.id.back_button);
        backButton.setOnClickListener(v -> finish());

        MaterialCardView card1 = findViewById(R.id.card1);
        MaterialCardView card2 = findViewById(R.id.card2);
        MaterialCardView card3 = findViewById(R.id.card3);

        card1.setOnClickListener(v -> {
            Intent intent = new Intent(NewspaperActivity.this, WebActivity.class);
            WebActivity.URL = "https://www.bd-pratidin.com/";
            WebActivity.TITLE = "বাংলাদেশ প্রতিদিন";
            startActivity(intent);
        });

        card2.setOnClickListener(v -> {
            Intent intent = new Intent(NewspaperActivity.this, WebActivity.class);
            WebActivity.URL = "https://barta24.com/";
            WebActivity.TITLE = "বার্তা ২৪";
            startActivity(intent);
        });

        card3.setOnClickListener(v -> {
            Intent intent = new Intent(NewspaperActivity.this, WebActivity.class);
            WebActivity.URL = "https://www.kalerkantho.com/";
            WebActivity.TITLE = "কালের কন্ঠ";
            startActivity(intent);
        });
    }
}