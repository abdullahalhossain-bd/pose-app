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
import android.widget.PopupMenu;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.Request;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonArrayRequest;
import com.example.betagiesheva.Adapter.DonorAdapter;
import com.example.betagiesheva.Model.Donor;

import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

import java.util.ArrayList;
import java.util.List;

public class BloodDonationActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private DonorAdapter donorAdapter;
    private List<Donor> donorList;
    private LottieAnimationView progressBar;
    private TextView noDataText;
    private EditText etSearch;
    private ImageView backButton;
    private ImageButton filterMenu;
    private CardView addButton;

    private static final String TAG = "BloodDonationActivity";

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

    private String selectedUnion = "সকল";
    private String currentSearch = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_blood_donation);

        initViews();
        setupRecyclerView();
        setupSearchListener();
        setupClickListeners();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadDonors();
    }

    private void initViews() {
        recyclerView = findViewById(R.id.recycler_view);
        progressBar = findViewById(R.id.progress);
        noDataText = findViewById(R.id.no_data_text);
        etSearch = findViewById(R.id.et_search);
        backButton = findViewById(R.id.back_button);
        filterMenu = findViewById(R.id.filter_menu);
        addButton = findViewById(R.id.add);
        donorList = new ArrayList<>();
    }

    private void setupRecyclerView() {
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        donorAdapter = new DonorAdapter(this, donorList);
        recyclerView.setAdapter(donorAdapter);
    }

    private void setupSearchListener() {
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) { }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearch = s.toString().trim();
                loadDonors();
            }

            @Override
            public void afterTextChanged(Editable s) { }
        });
    }

    private void setupClickListeners() {
        backButton.setOnClickListener(v -> finish());
        filterMenu.setOnClickListener(v -> showUnionFilterMenu());
        addButton.setOnClickListener(v -> startActivity(new Intent(BloodDonationActivity.this, AddBloodDonationActivity.class)));
    }

    private void showUnionFilterMenu() {
        PopupMenu popupMenu = new PopupMenu(this, filterMenu);
        for (int i = 0; i < unionNames.length; i++) {
            popupMenu.getMenu().add(0, i, i, unionNames[i]);
        }

        popupMenu.setOnMenuItemClickListener(item -> {
            int position = item.getItemId();
            selectedUnion = unionNames[position];
            etSearch.setText("");
            loadDonors();
            Toast.makeText(this, selectedUnion + " নির্বাচিত হয়েছে", Toast.LENGTH_SHORT).show();
            return true;
        });

        popupMenu.show();
    }

    private void loadDonors() {
        showLoading(true);

        String url = Config.GET_DONOR;
        StringBuilder params = new StringBuilder();

        // Server's get_donor.php expects ?name= (NOT ?search=).
        // The blood_donors table has NO union column, so union filtering is
        // not supported server-side — we drop that param here.
        if (!currentSearch.isEmpty()) {
            params.append("?name=").append(Uri.encode(currentSearch));
        }

        url = url + params.toString();
        Log.d(TAG, "Loading donors from URL: " + url);

        JsonArrayRequest request = new JsonArrayRequest(
                Request.Method.GET,
                url,
                null,
                response -> {
                    donorList.clear();
                    Log.d(TAG, "API Response received. Array length: " + response.length());
                    
                    try {
                        for (int i = 0; i < response.length(); i++) {
                            JSONObject obj = response.getJSONObject(i);

                            Donor donor = new Donor();
                            donor.setId(obj.optString("id"));
                            donor.setName(obj.optString("name"));
                            donor.setAddress(obj.optString("address"));
                            donor.setBloodGroup(obj.optString("blood_group"));
                            donor.setPhone(obj.optString("phone"));
                            donor.setImage(obj.optString("image", ""));

                            donorList.add(donor);
                            Log.d(TAG, "Added donor: " + donor.getName() + " | Blood: " + donor.getBloodGroup());
                        }

                        Log.i(TAG, "Successfully parsed " + donorList.size() + " donors from JSON");
                        Log.d(TAG, "RecyclerView visible before notify: " + (recyclerView.getVisibility() == View.VISIBLE));
                        
                        donorAdapter.notifyDataSetChanged();
                        showLoading(false);
                        updateEmptyView();
                        
                        Log.d(TAG, "Donors displayed. List size: " + donorList.size());

                    } catch (JSONException e) {
                        Log.e(TAG, "JSON parsing error: " + e.getMessage() + "\nResponse: " + response.toString(), e);
                        e.printStackTrace();
                        showLoading(false);
                        Toast.makeText(this, "ডাটা প্রসেস করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                        updateEmptyView();
                    }
                },
                error -> {
                    showLoading(false);
                    
                    if (error == null) {
                        Log.e(TAG, "API Error: Unknown error occurred");
                    } else {
                        Log.e(TAG, "API Error Code: " + error.networkResponse);
                        
                        if (error.networkResponse != null) {
                            int statusCode = error.networkResponse.statusCode;
                            String responseBody = new String(error.networkResponse.data);
                            Log.e(TAG, "HTTP Status Code: " + statusCode);
                            Log.e(TAG, "Response Body: " + responseBody);
                        }
                        
                        if (error.getMessage() != null) {
                            Log.e(TAG, "Error Message: " + error.getMessage());
                        }
                        
                        if (error.getCause() != null) {
                            Log.e(TAG, "Error Cause: " + error.getCause().toString(), error);
                        }
                    }
                    
                    error.printStackTrace();
                    Toast.makeText(this, "ডাটা লোড করতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                    updateEmptyView();
                }
        );

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void showLoading(boolean show) {
        Log.d(TAG, "showLoading(" + show + ") - Setting visibility");
        progressBar.setVisibility(show ? View.VISIBLE : View.GONE);
        recyclerView.setVisibility(show ? View.GONE : View.VISIBLE);
        Log.d(TAG, "After showLoading - RecyclerView visibility: " + recyclerView.getVisibility() + " (8=GONE, 0=VISIBLE)");
    }

    private void updateEmptyView() {
        Log.d(TAG, "updateEmptyView() - donorList size: " + donorList.size());
        if (donorList.isEmpty()) {
            Log.d(TAG, "No donors - showing empty state");
            noDataText.setVisibility(View.VISIBLE);
            recyclerView.setVisibility(View.GONE);
        } else {
            Log.d(TAG, "Donors found - showing RecyclerView");
            noDataText.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);
            Log.d(TAG, "RecyclerView visibility set to: " + recyclerView.getVisibility());
        }
    }
}
