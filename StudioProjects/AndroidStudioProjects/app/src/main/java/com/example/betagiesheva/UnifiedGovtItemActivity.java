package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import android.widget.PopupMenu;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Adapter.UnifiedGovtItemAdapter;
import com.example.betagiesheva.Model.UnifiedGovtItem;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class UnifiedGovtItemActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private UnifiedGovtItemAdapter adapter;
    private List<UnifiedGovtItem> itemList;

    private LottieAnimationView progress;
    private TextView noDataText;
    private EditText etSearch;
    private ImageView backButton;
    private ImageButton filterMenu;
    private FloatingActionButton fabAdd;
    private SessionManager sessionManager;

    private String govtType = "";
    private String selectedUnion = "";
    private String currentSearchText = "";

    String[] unionNames = {
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
        setContentView(R.layout.activity_unified_govt_item);

        initViews();
        setupRecycler();

        govtType = getIntent().getStringExtra("govtType");

        setupSearch();
        setupFilterMenu();
        setupFabVisibility();

        backButton.setOnClickListener(v -> finish());
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadGovtItems();
    }

    private void initViews() {
        recyclerView = findViewById(R.id.recycler_view);
        progress = findViewById(R.id.progress);
        noDataText = findViewById(R.id.no_data_text);
        etSearch = findViewById(R.id.et_search);
        backButton = findViewById(R.id.back_button);
        filterMenu = findViewById(R.id.filter_menu);
        fabAdd = findViewById(R.id.fab_add);
    }

    private void setupRecycler() {
        itemList = new ArrayList<>();
        adapter = new UnifiedGovtItemAdapter(this, itemList);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);
    }

    // ✅ FILTER MENU
    private void setupFilterMenu() {
        filterMenu.setOnClickListener(v -> {
            PopupMenu menu = new PopupMenu(this, filterMenu);

            menu.getMenu().add("সকল ইউনিয়ন");
            for (String union : unionNames) {
                menu.getMenu().add(union);
            }

            menu.setOnMenuItemClickListener(item -> {
                String title = item.getTitle().toString();
                selectedUnion = title.equals("সকল ইউনিয়ন") ? "" : title;
                loadGovtItems();
                return true;
            });

            menu.show();
        });
    }

    // ✅ FAB VISIBILITY
    private void setupFabVisibility() {
        sessionManager = new SessionManager(this); // initialize

        // Get user type from SharedPreferences
        String userType = sessionManager.getUserType(); // should return "Admin" or "User"

        // Show FAB only if user is admin
        if ("Admin".equalsIgnoreCase(userType)) { // ignore case
            fabAdd.setVisibility(View.VISIBLE);
            fabAdd.setOnClickListener(v -> startActivity(new Intent(UnifiedGovtItemActivity.this, AddUnifiedGovtItemActivity.class)
                    .putExtra("govtType", govtType)));
        } else {
            fabAdd.setVisibility(View.GONE);
        }
    }

    // ✅ API CALL
    private void loadGovtItems() {

        progress.setVisibility(View.VISIBLE);
        noDataText.setVisibility(View.GONE);

        // Build URL with proper encoding
        Uri.Builder builder = Uri.parse(Config.BASE_URL + "get_unified_govt_item.php").buildUpon();

        if (govtType != null && !govtType.isEmpty()) {
            builder.appendQueryParameter("item_type", govtType);
        }

        if (!selectedUnion.isEmpty()) {
            builder.appendQueryParameter("union", selectedUnion);
        }

        if (!currentSearchText.isEmpty()) {
            builder.appendQueryParameter("search", currentSearchText);
        }

        String url = builder.build().toString();

        StringRequest request = new StringRequest(
                Request.Method.GET,
                url,
                response -> {
                    progress.setVisibility(View.GONE);
                    parseResponse(response);
                },
                error -> {
                    progress.setVisibility(View.GONE);
                    Toast.makeText(this, "ডাটা লোড ব্যর্থ", Toast.LENGTH_SHORT).show();
                }
        );

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void parseResponse(String response) {
        try {
            JSONArray array = new JSONArray(response);
            List<UnifiedGovtItem> tempList = new ArrayList<>();

            for (int i = 0; i < array.length(); i++) {
                JSONObject obj = array.getJSONObject(i);

                UnifiedGovtItem item = new UnifiedGovtItem();
                item.setId(obj.getInt("id"));
                item.setName(obj.optString("name"));
                item.setAddress(obj.optString("address"));
                item.setPhoneNumber(obj.optString("phone_number"));
                item.setImgUrl(obj.optString("img_url"));
                item.setUnion(obj.optString("union_name"));
                item.setCreatedAt(obj.optString("created_at"));
                item.setUpdatedAt(obj.optString("updated_at"));

                String typeName = obj.optString("item_type");
                item.setItemType(UnifiedGovtItem.ItemType.fromDisplayName(typeName));

                tempList.add(item);
            }

            adapter.updateList(tempList);

            noDataText.setVisibility(tempList.isEmpty() ? View.VISIBLE : View.GONE);

        } catch (Exception e) {
            noDataText.setVisibility(View.VISIBLE);
        }
    }

    // ✅ SEARCH
    private void setupSearch() {
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearchText = s.toString();
                loadGovtItems();
            }

            @Override public void afterTextChanged(Editable s) {}
        });
    }
}