package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.toolbox.JsonArrayRequest;
import com.example.betagiesheva.Adapter.UnifiedGovtOfficerAdapter;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedGovtOfficer;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class UnifiedGovtOfficerActivity extends AppCompatActivity {

    private static final String TAG = "UnifiedOfficerActivity";

    private RecyclerView recyclerView;
    private UnifiedGovtOfficerAdapter adapter;
    private TextView noDataText;
    private EditText searchEditText;
    private ImageView backButton;
    private FloatingActionButton fabAdd;
    private SessionManager sessionManager;

    private List<UnifiedGovtOfficer> officerList = new ArrayList<>();
    private String currentOfficerType = "";
    private String currentSearch = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_unified_govt_officer);

        initViews();
        getCurrentOfficerType();
        setupRecyclerView();
        setupSearch();
        setupFabVisibility();
        setupBackButton();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadDataFromServer();
    }

    private void initViews() {
        recyclerView = findViewById(R.id.recycler_view);
        noDataText = findViewById(R.id.no_data_text);
        searchEditText = findViewById(R.id.et_search);
        backButton = findViewById(R.id.back_button);
        fabAdd = findViewById(R.id.fab_add);
    }

    private void getCurrentOfficerType() {
        if (getIntent().hasExtra("officerType")) {
            currentOfficerType = getIntent().getStringExtra("officerType");
            Log.d(TAG, "Officer type from intent: " + currentOfficerType);
        }
    }

    private void setupRecyclerView() {
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new UnifiedGovtOfficerAdapter(this, officerList);
        recyclerView.setAdapter(adapter);
    }

    private void setupSearch() {
        searchEditText.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearch = s.toString().trim();
                loadDataFromServer();
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        searchEditText.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                currentSearch = searchEditText.getText().toString().trim();
                loadDataFromServer();
                hideKeyboard();
                return true;
            }
            return false;
        });
    }

    private void setupBackButton() {
        backButton.setOnClickListener(v -> finish());
    }

    private void setupFabVisibility() {
        sessionManager = new SessionManager(this);

        // Show FAB only for admin
        if ("Admin".equalsIgnoreCase(sessionManager.getUserType())) {
            fabAdd.setVisibility(FloatingActionButton.VISIBLE);
            fabAdd.setOnClickListener(v -> startActivity(
                    new Intent(UnifiedGovtOfficerActivity.this, AddUnifiedGovtOfficerActivity.class)
                            .putExtra("officer_type", currentOfficerType)
            ));
        } else {
            fabAdd.setVisibility(FloatingActionButton.GONE);
        }
    }

    private void loadDataFromServer() {
        showLoading(true);

        // Server's get_unified_govt_officer.php only supports ?officer_type= filter.
        // The unified_govt_officers table has no union column, and the server
        // doesn't accept ?search= — filter search client-side.
        Uri.Builder builder = Uri.parse(Config.GET_UNIFIED_GOVT_OFFICER).buildUpon();
        if (currentOfficerType != null && !currentOfficerType.isEmpty()) {
            builder.appendQueryParameter("officer_type", currentOfficerType);
        }

        String url = builder.build().toString();

        // IMPORTANT: server returns a RAW JSON ARRAY for list endpoints (not a
        // wrapped {success, data} object). Use JsonArrayRequest, not StringRequest.
        JsonArrayRequest request = new JsonArrayRequest(
                Request.Method.GET,
                url,
                null,
                response -> {
                    try {
                        officerList.clear();

                        for (int i = 0; i < response.length(); i++) {
                            JSONObject obj = response.getJSONObject(i);
                            String name = obj.optString("name", "");
                            String designation = obj.optString("designation", "");
                            String officerType = obj.optString("officer_type", "");

                            // Client-side search filter
                            if (!currentSearch.isEmpty()) {
                                String q = currentSearch.toLowerCase();
                                if (!name.toLowerCase().contains(q)
                                        && !designation.toLowerCase().contains(q)
                                        && !officerType.toLowerCase().contains(q)) {
                                    continue;
                                }
                            }

                            UnifiedGovtOfficer officer = new UnifiedGovtOfficer(
                                    obj.optString("id", ""),
                                    name,
                                    designation,
                                    obj.optString("phone_number", ""),
                                    obj.optString("image", ""),
                                    officerType
                            );
                            officerList.add(officer);
                        }

                        updateUIVisibility();
                    } catch (Exception e) {
                        Log.e(TAG, "Parse error: " + e.getMessage());
                        showError("ডেটা প্রসেস করতে সমস্যা হয়েছে");
                    }
                    showLoading(false);
                },
                error -> {
                    Log.e(TAG, "Network error: " + error.toString());
                    showError("ইন্টারনেট সংযোগ চেক করুন");
                    showLoading(false);
                }
        );

        request.setTag(TAG);
        Config.getInstance(this).addToRequestQueue(request);
    }

    private UnifiedGovtOfficer parseOfficer(JSONObject obj) throws Exception {
        return new UnifiedGovtOfficer(
                obj.optString("id", ""),
                obj.optString("name", ""),
                obj.optString("designation", ""),
                obj.optString("phone_number", ""),
                obj.optString("image", ""),
                obj.optString("officer_type", "")
        );
    }

    private void updateUIVisibility() {
        if (officerList.isEmpty()) {
            noDataText.setVisibility(TextView.VISIBLE);
            String message = currentOfficerType != null && !currentOfficerType.isEmpty()
                    ? currentOfficerType + " বিভাগে কোন কর্মকর্তা পাওয়া যায়নি"
                    : "কোন কর্মকর্তা পাওয়া যায়নি";
            noDataText.setText(message);
            recyclerView.setVisibility(RecyclerView.GONE);
        } else {
            noDataText.setVisibility(TextView.GONE);
            recyclerView.setVisibility(RecyclerView.VISIBLE);
        }
        adapter.updateList(new ArrayList<>(officerList));
    }

    private void showLoading(boolean show) {
        if (show) {
            noDataText.setVisibility(TextView.VISIBLE);
            noDataText.setText("লোড হচ্ছে...");
            recyclerView.setVisibility(RecyclerView.GONE);
        }
    }

    private void showError(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        noDataText.setVisibility(TextView.VISIBLE);
        noDataText.setText(message);
        recyclerView.setVisibility(RecyclerView.GONE);
    }

    private void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (imm != null && getCurrentFocus() != null) {
            imm.hideSoftInputFromWindow(getCurrentFocus().getWindowToken(), 0);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Config.getInstance(this).getRequestQueue().cancelAll(TAG);
    }
}