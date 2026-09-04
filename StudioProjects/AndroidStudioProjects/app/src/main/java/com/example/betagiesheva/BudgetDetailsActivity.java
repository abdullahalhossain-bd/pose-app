package com.example.betagiesheva;

import android.os.Bundle;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.example.betagiesheva.Adapter.BudgetCategoryAdapter;
import com.example.betagiesheva.Model.BudgetCategoryModel;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class BudgetDetailsActivity extends AppCompatActivity {

    Toolbar toolbar;
    TextView totalBudgetText, spentAmountText, remainingAmountText, budgetDetailsError;
    ProgressBar overallProgressBar, budgetDetailsLoading;
    RecyclerView categoryRecyclerView;

    ArrayList<BudgetCategoryModel> categoryList;
    BudgetCategoryAdapter adapter;

    SessionManager sessionManager;
    String userId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_budget_details);

        initViews();
        setupToolbar();
        setupRecycler();

        sessionManager = new SessionManager(this);

        loadBudgetDetails();
    }

    // 🔹 View binding
    private void initViews() {
        toolbar = findViewById(R.id.toolbar);
        totalBudgetText = findViewById(R.id.totalBudgetText);
        spentAmountText = findViewById(R.id.spentAmountText);
        remainingAmountText = findViewById(R.id.remainingAmountText);
        overallProgressBar = findViewById(R.id.overallProgressBar);
        budgetDetailsLoading = findViewById(R.id.budgetDetailsLoading);
        budgetDetailsError = findViewById(R.id.budgetDetailsError);
        categoryRecyclerView = findViewById(R.id.categoryRecyclerView);
    }

    // 🔹 Toolbar
    private void setupToolbar() {
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("বাজেট বিস্তারিত");
        }
        toolbar.setNavigationOnClickListener(v -> finish());
    }

    // 🔹 RecyclerView
    private void setupRecycler() {
        categoryList = new ArrayList<>();
        adapter = new BudgetCategoryAdapter(this, categoryList);
        categoryRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        categoryRecyclerView.setAdapter(adapter);
    }

    // 🔹 API call
    private void loadBudgetDetails() {

        budgetDetailsLoading.setVisibility(View.VISIBLE);
        budgetDetailsError.setVisibility(View.GONE);

        StringRequest request = new StringRequest(
                Request.Method.POST,
                Config.BUDGET_DETAILS_URL,
                response -> {
                    budgetDetailsLoading.setVisibility(View.GONE);

                    try {
                        JSONObject json = new JSONObject(response);

                        if (json.getBoolean("success")) {

                            JSONObject summary = json.getJSONObject("summary");

                            double total = summary.getDouble("total_budget");
                            double spent = summary.getDouble("spent_budget");
                            double remaining = summary.getDouble("remaining_budget");

                            totalBudgetText.setText("৳ " + total);
                            spentAmountText.setText("ব্যয়িত: ৳ " + spent);
                            remainingAmountText.setText("অবশিষ্ট: ৳ " + remaining);

                            int progress = (int) ((spent / total) * 100);
                            overallProgressBar.setProgress(progress);

                            // 🔹 Category list
                            JSONArray categories = json.getJSONArray("categories");
                            categoryList.clear();

                            for (int i = 0; i < categories.length(); i++) {
                                JSONObject obj = categories.getJSONObject(i);

                                BudgetCategoryModel model = new BudgetCategoryModel(
                                        obj.getString("category_name"),
                                        obj.getDouble("allocated_amount"),
                                        obj.getDouble("spent_amount")
                                );

                                categoryList.add(model);
                            }

                            adapter.notifyDataSetChanged();

                        } else {
                            showError(json.getString("message"));
                        }

                    } catch (Exception e) {
                        showError("ডাটা প্রসেস করতে সমস্যা হচ্ছে");
                    }
                },
                error -> {
                    budgetDetailsLoading.setVisibility(View.GONE);
                    showError("সার্ভারের সাথে সংযোগ করা যায়নি");
                }
        ) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> map = new HashMap<>();
                map.put("user_id", userId);
                return map;
            }
        };

        RequestQueue queue = Volley.newRequestQueue(this);
        queue.add(request);
    }

    // 🔹 Error handler
    private void showError(String msg) {
        budgetDetailsError.setVisibility(View.VISIBLE);
        budgetDetailsError.setText(msg);
    }
}
