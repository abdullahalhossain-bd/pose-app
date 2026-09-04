package com.example.betagiesheva;


import android.app.Dialog;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.card.MaterialCardView;

import java.util.HashMap;
import java.util.Map;

public class ShopActivity extends AppCompatActivity {

    private ImageView backButton;
    private MaterialCardView marketRateCard;
    private MaterialCardView card1, card2, card3, card4, card5, card6, card7, card8;

    // Java replacement for Kotlin data class
    private static class ShopCategory {
        String businessType;
        String displayName;

        ShopCategory(String businessType, String displayName) {
            this.businessType = businessType;
            this.displayName = displayName;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shop);

        // Initialize views
        backButton = findViewById(R.id.back);
        marketRateCard = findViewById(R.id.custom_dialog_market);
        card1 = findViewById(R.id.card1);
        card2 = findViewById(R.id.card2);
        card3 = findViewById(R.id.card3);
        card4 = findViewById(R.id.card4);
        card5 = findViewById(R.id.card5);
        card6 = findViewById(R.id.card6);
        card7 = findViewById(R.id.card7);
        card8 = findViewById(R.id.card8);

        // Back button
        backButton.setOnClickListener(v -> finish());

        // Market rate dialog
        marketRateCard.setOnClickListener(v -> showMarketRateDialog());

        // Card click listeners
        setupCardClickListeners();
    }

    private void setupCardClickListeners() {

        Map<Integer, ShopCategory> shopCategories = new HashMap<>();
        shopCategories.put(R.id.card1, new ShopCategory("grocery_shop", "মুদি দোকান"));
        shopCategories.put(R.id.card2, new ShopCategory("furniture_shop", "ফার্নিচার দোকান"));
        shopCategories.put(R.id.card3, new ShopCategory("concrete_shop", "কংক্রিট দোকান"));
        shopCategories.put(R.id.card4, new ShopCategory("decorator_shop", "ডেকোরেটরস দোকান"));
        shopCategories.put(R.id.card5, new ShopCategory("electronics_shop", "ইলেকট্রনিক্স দোকান"));
        shopCategories.put(R.id.card6, new ShopCategory("jewelers_shop", "জুয়েলার্স দোকান"));
        shopCategories.put(R.id.card7, new ShopCategory("clothing_shop", "কাপড়ের দোকান"));
        shopCategories.put(R.id.card8, new ShopCategory("library", "লাইব্রেরি"));

        View.OnClickListener listener = view -> {
            ShopCategory category = shopCategories.get(view.getId());
            if (category != null) {
                Intent intent = new Intent(ShopActivity.this, UnifiedBusinessItemActivity.class);
                intent.putExtra("businessType", category.businessType);
                intent.putExtra("displayName", category.displayName);
                startActivity(intent);
            }
        };

        card1.setOnClickListener(listener);
        card2.setOnClickListener(listener);
        card3.setOnClickListener(listener);
        card4.setOnClickListener(listener);
        card5.setOnClickListener(listener);
        card6.setOnClickListener(listener);
        card7.setOnClickListener(listener);
        card8.setOnClickListener(listener);
    }

    private void showMarketRateDialog() {
        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.dialog_market_rate);
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        }
        dialog.setCancelable(true);

        Button btnClose = dialog.findViewById(R.id.btn_close);
        btnClose.setOnClickListener(v -> dialog.dismiss());

        dialog.show();
    }
}
