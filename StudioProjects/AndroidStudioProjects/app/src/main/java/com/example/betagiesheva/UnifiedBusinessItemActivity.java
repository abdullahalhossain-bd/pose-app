package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.PopupMenu;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Adapter.UnifiedBusinessAdapter;
import com.example.betagiesheva.Model.UnifiedBusinessItem;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.List;

public class UnifiedBusinessItemActivity extends AppCompatActivity {
    private CardView add;
    private ImageView backButton, filterMenu;
    private EditText searchEditText;
    private TextView noDataText;
    private RecyclerView recyclerView;
    private LottieAnimationView progressBar;

    private UnifiedBusinessAdapter adapter;
    private final List<UnifiedBusinessItem> businessList = new ArrayList<>();

    private String businessType = "";
    private String category = "";
    private String displayName = "";
    private String selectedUnion = "";
    private String currentSearch = "";

    private final String[] unionNames = {
            "সকল",
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
        setContentView(R.layout.activity_unified_business_item);

        getIntentData();
        initViews();
        setupRecyclerView();
        setupSearch();
        setupUnionFilter();
        setupBackButton();
        setupAddButton();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadBusinessData();
    }

    private void getIntentData() {
        if (getIntent() != null) {
            businessType = getIntent().getStringExtra("businessType");
            category = getIntent().getStringExtra("category");
            displayName = getIntent().getStringExtra("displayName");
        }

        if (businessType == null) businessType = "";
        if (category == null) category = "";
        if (displayName == null) displayName = "";
    }

    private void initViews() {
        add = findViewById(R.id.add);
        backButton = findViewById(R.id.back_button);
        filterMenu = findViewById(R.id.filter_menu);
        searchEditText = findViewById(R.id.et_search);
        noDataText = findViewById(R.id.no_data_text);
        recyclerView = findViewById(R.id.recycler_view);
        progressBar = findViewById(R.id.progress);

        if (getSupportActionBar() != null && !displayName.isEmpty()) {
            getSupportActionBar().setTitle(displayName);
        }
    }

    private void setupRecyclerView() {
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new UnifiedBusinessAdapter(this, businessList);
        recyclerView.setAdapter(adapter);
    }

    private void setupSearch() {
        searchEditText.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearch = s.toString();
                loadBusinessData();
            }
            @Override public void afterTextChanged(Editable s) {}
        });
    }

    private void setupUnionFilter() {
        filterMenu.setOnClickListener(v -> {
            PopupMenu popupMenu = new PopupMenu(this, filterMenu);

            for (String union : unionNames) {
                popupMenu.getMenu().add(union);
            }

            popupMenu.setOnMenuItemClickListener(item -> {
                String selected = item.getTitle().toString();
                selectedUnion = selected.equals("সকল") ? "" : selected;
                Log.d("UNION_FILTER", "Selected union = " + selectedUnion);
                loadBusinessData();
                return true;
            });

            popupMenu.show();
        });
    }

    private void setupAddButton() {
        add.setOnClickListener(v -> {
            Intent intent = new Intent(
                    UnifiedBusinessItemActivity.this,
                    AddUnifiedBusinessItemActivity.class
            );

            String typeToPass = category.isEmpty() ? businessType : category;
            intent.putExtra("businessType", typeToPass);
            intent.putExtra("displayName", displayName);

            startActivity(intent);
        });
    }

    private void setupBackButton() {
        backButton.setOnClickListener(v -> finish());
    }

    private void loadBusinessData() {
        showLoading(true);

        Uri.Builder builder = Uri.parse(Config.BUSINESS_ITEMS_URL).buildUpon();
        String typeParam = category.isEmpty() ? businessType : category;

        builder.appendQueryParameter("type", typeParam);
        if (!selectedUnion.isEmpty()) {
            builder.appendQueryParameter("union", selectedUnion);
        }
        if (!currentSearch.isEmpty()) {
            builder.appendQueryParameter("search", currentSearch);
        }

        String url = builder.build().toString();
        Log.d("API_URL", url);

        StringRequest request = new StringRequest(
                Request.Method.GET,
                url,
                response -> {
                    try {
                        JSONArray array = new JSONArray(response);
                        businessList.clear();

                        for (int i = 0; i < array.length(); i++) {
                            JSONObject obj = array.getJSONObject(i);

                            // ✅ FIXED: Correct parameter order matching the constructor
                            UnifiedBusinessItem item = new UnifiedBusinessItem(
                                    obj.optString("id"),
                                    obj.optString("user_id"),
                                    obj.optString("name"),
                                    obj.optString("proprietor_name"),  // ✅ 4th param
                                    obj.optString("phone"),             // ✅ 5th param
                                    obj.optString("address"),           // ✅ 6th param
                                    obj.optString("union_name"),        // ✅ 7th param
                                    obj.optString("business_type"),     // ✅ 8th param
                                    obj.optString("details"),           // ✅ 9th param
                                    obj.optString("image"),             // ✅ 10th param
                                    obj.optString("created_at"),        // ✅ 11th param
                                    obj.optString("updated_at")         // ✅ 12th param
                            );

                            businessList.add(item);
                        }

                        updateUI();

                    } catch (Exception e) {
                        e.printStackTrace();
                        showError("ডেটা প্রসেস করতে সমস্যা হয়েছে");
                    }
                    showLoading(false);
                },
                error -> {
                    error.printStackTrace();
                    showError("ইন্টারনেট সংযোগ চেক করুন");
                    showLoading(false);
                }
        ) {
            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String utf8 = new String(response.data, "UTF-8");
                    return Response.success(utf8,
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response));
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }
        };

        request.setRetryPolicy(new DefaultRetryPolicy(
                30000,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT
        ));

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void updateUI() {
        if (businessList.isEmpty()) {
            recyclerView.setVisibility(View.GONE);
            noDataText.setVisibility(View.VISIBLE);
            String msg = currentSearch.isEmpty() 
                    ? (selectedUnion.isEmpty() ? "কোন তথ্য পাওয়া যায়নি" : selectedUnion + " এ কোন ব্যবসা পাওয়া যায়নি")
                    : "\"" + currentSearch + "\" এর জন্য কোন ফলাফল নেই";
            noDataText.setText(msg);
        } else {
            noDataText.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);
            adapter.notifyDataSetChanged();
        }
    }

    private void showLoading(boolean show) {
        progressBar.setVisibility(show ? View.VISIBLE : View.GONE);
        if (show) recyclerView.setVisibility(View.GONE);
    }

    private void showError(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
        noDataText.setVisibility(View.VISIBLE);
        noDataText.setText(msg);
        recyclerView.setVisibility(View.GONE);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Config.getInstance(this).getRequestQueue().cancelAll(tag -> true);
    }
}
