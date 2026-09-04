package com.example.betagiesheva;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.cardview.widget.CardView;

public class EduActivity extends AppCompatActivity {
    private ImageView back;
    private CardView card1;
    private CardView card2;
    private CardView card3;
    private CardView card4;
    private CardView card5;
    private CardView card6;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_edu);


        back = findViewById(R.id.back);
        card1 = findViewById(R.id.card1);
        card2 = findViewById(R.id.card2);
        card3 = findViewById(R.id.card3);
        card4 = findViewById(R.id.card4);

        back.setOnClickListener(v -> {
            Intent intent = new Intent(EduActivity.this, MainActivity.class);
            startActivity(intent);
        });

        card1.setOnClickListener(v -> {
            Intent intent = new Intent(EduActivity.this, PrimaryActivity.class);
            startActivity(intent);
        });

        card2.setOnClickListener(v -> {
            Intent intent = new Intent(EduActivity.this, HighActivity.class);
            startActivity(intent);
        });

        card3.setOnClickListener(v -> {
            Intent intent = new Intent(EduActivity.this, CollegeActivity.class);
            startActivity(intent);
        });

        card4.setOnClickListener(v -> {
            Intent intent = new Intent(EduActivity.this, MadrasaActivity.class);
            startActivity(intent);
        });
    }
}