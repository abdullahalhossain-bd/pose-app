package com.example.betagiesheva;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.PopupMenu;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Adapter.ClinicAdapter;
import com.example.betagiesheva.Model.Clinic;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class ClinicActivity extends AppCompatActivity implements ClinicAdapter.OnClinicClickListener {
    private ClinicAdapter clinicAdapter;
    private List<Clinic> clinicList;
    private List<Clinic> filteredList;
    private com.airbnb.lottie.LottieAnimationView progressView;
    private RecyclerView recyclerView;
    private EditText searchEditText;
    private ImageButton filterButton;
    private ImageView backButton;
    private FloatingActionButton fabAdd;


    private String currentUnionFilter = "";
    private SessionManager sessionManager;
    private String currentSearch = "";


    // Union names
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
        setContentView(R.layout.activity_clinic);

        initializeViews();
        setupRecyclerView();
        setupClickListeners();
        setupSearchBar();
        setupFabVisibility();

        loadClinicsFromApi();
    }

    private void initializeViews() {
        recyclerView = findViewById(R.id.recycler_view);
        progressView = findViewById(R.id.progress);
        searchEditText = findViewById(R.id.et_search);
        filterButton = findViewById(R.id.filter_menu);
        backButton = findViewById(R.id.backIcon);
        fabAdd = findViewById(R.id.fab_add);

        clinicList = new ArrayList<>();
        filteredList = new ArrayList<>();
    }

    private void setupRecyclerView() {
        clinicAdapter = new ClinicAdapter(this, filteredList, this);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(clinicAdapter);
    }

    private void setupClickListeners() {
        backButton.setOnClickListener(v -> finish());
        filterButton.setOnClickListener(v -> showFilterOptions());
    }

    private void setupFabVisibility() {
        sessionManager = new SessionManager(this); // initialize

        // Get user type from SharedPreferences
        String userType = sessionManager.getUserType(); // should return "Admin" or "User"

        // Show FAB only if user is admin
        if ("Admin".equalsIgnoreCase(userType)) { // ignore case
            fabAdd.setVisibility(View.VISIBLE);
            fabAdd.setOnClickListener(v -> startActivity(new Intent(ClinicActivity.this, AddClinicActivity.class)));
        } else {
            fabAdd.setVisibility(View.GONE);
        }
    }

    private void setupSearchBar() {
        searchEditText.setHint("ক্লিনিক খুঁজুন");

        // Add TextWatcher for real-time search
        searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                // Not needed
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                // Search via API as user types
                currentSearch = s.toString();
                loadClinicsFromApi();
            }

            @Override
            public void afterTextChanged(Editable s) {
                // Not needed
            }
        });

        // Handle keyboard search button
        searchEditText.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                loadClinicsFromApi();
                // Hide keyboard
                InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
                imm.hideSoftInputFromWindow(searchEditText.getWindowToken(), 0);
                return true;
            }
            return false;
        });
    }

    private void loadClinicsFromApi() {
        if (progressView != null) progressView.setVisibility(View.VISIBLE);

        // Build URL with search and union filter params
        String url = Config.Get_Clinic;
        StringBuilder urlParams = new StringBuilder();

        if (!currentSearch.isEmpty()) {
            urlParams.append("?search=").append(Uri.encode(currentSearch));
        }
        if (!currentUnionFilter.isEmpty()) {
            if (urlParams.length() > 0) {
                urlParams.append("&union=").append(Uri.encode(currentUnionFilter));
            } else {
                urlParams.append("?union=").append(Uri.encode(currentUnionFilter));
            }
        }

        String requestUrl = url + urlParams.toString();

        StringRequest request = new StringRequest(
                Request.Method.GET,
                requestUrl,
                response -> {
                    try {
                        JSONArray clinicsArray = new JSONArray(response);
                        clinicList.clear();
                        filteredList.clear();

                        for (int i = 0; i < clinicsArray.length(); i++) {
                            JSONObject obj = clinicsArray.getJSONObject(i);
                            Clinic clinic = new Clinic();

                            clinic.setId(obj.getString("id"));
                            clinic.setName(obj.optString("name", ""));
                            clinic.setAddress(obj.optString("address", ""));
                            clinic.setImg(obj.optString("img", ""));
                            clinic.setPlaceName(obj.optString("place_name", ""));
                            clinic.setPhoneNumber(obj.optString("phone_number", ""));
                            clinic.setComplaintPhoneNumber(obj.optString("complaint_phone_number", "N/A"));
                            clinic.setFounderName(obj.optString("founder_name", "N/A"));
                            clinic.setEstablishDate(obj.optString("establish_date", "N/A"));
                            clinic.setTransportInfo(obj.optString("transport_info", "N/A"));
                            clinic.setOperatingHours(obj.optString("operating_hours", "N/A"));
                            clinic.setEmail(obj.optString("email", "N/A"));
                            clinic.setUnion(obj.optString("union", ""));

                            // Parse services — server stores/returns this as a JSON ARRAY
                            // of {"test_name": ..., "fee": ...} objects, NOT a map, so it
                            // must be read with optJSONArray (optJSONObject always returned
                            // null here, silently dropping every service).
                            JSONArray servicesArray = obj.optJSONArray("services");
                            Map<String, Object> services = new HashMap<>();
                            if (servicesArray != null) {
                                for (int j = 0; j < servicesArray.length(); j++) {
                                    JSONObject svc = servicesArray.optJSONObject(j);
                                    if (svc == null) continue;
                                    String testName = svc.optString("test_name", "");
                                    double fee = svc.optDouble("fee", 0.0);
                                    if (!testName.isEmpty()) {
                                        services.put(testName, fee);
                                    }
                                }
                            }
                            clinic.setServices(services);

                            clinicList.add(clinic);
                            filteredList.add(clinic);
                        }

                        clinicAdapter.notifyDataSetChanged();
                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(this, "JSON parsing error: " + e.getMessage(), Toast.LENGTH_LONG).show();

                    }

                    if (progressView != null) progressView.setVisibility(View.GONE);
                },
                error -> {
                    if (progressView != null) progressView.setVisibility(View.GONE);
                    Toast.makeText(this, "Network error: " + error.getMessage(), Toast.LENGTH_LONG).show();

                }
        ) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                Map<String, String> headers = new HashMap<>();
                headers.put("Accept-Charset", "UTF-8");
                headers.put("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                return headers;
            }

            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                try {
                    String utf8String = new String(response.data, "UTF-8");
                    return Response.success(utf8String,
                            com.android.volley.toolbox.HttpHeaderParser.parseCacheHeaders(response));
                } catch (UnsupportedEncodingException e) {
                    return super.parseNetworkResponse(response);
                }
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }

    private Clinic createClinic(String id, String name, String address, String founder,
                                String hours, String estDate, String phone, String email,
                                String complaintPhone, String transport, String union) {
        Clinic clinic = new Clinic();
        clinic.setId(id);
        clinic.setName(name);
        clinic.setAddress(address);
        clinic.setFounderName(founder);
        clinic.setOperatingHours(hours);
        clinic.setEstablishDate(estDate);
        clinic.setPhoneNumber(phone);
        clinic.setEmail(email);
        clinic.setComplaintPhoneNumber(complaintPhone);
        clinic.setTransportInfo(transport);
        clinic.setPlaceName("betagi");
        clinic.setImg("");
        clinic.setUnion(union);

        Map<String, Object> services = new HashMap<>();
        services.put("সাধারণ পরামর্শ", 500.0);
        services.put("রক্ত পরীক্ষা", 300.0);
        services.put("এক্স-রে", 800.0);
        services.put("ইসিজি", 600.0);
        clinic.setServices(services);

        return clinic;
    }


    private void showFilterOptions() {
        PopupMenu menu = new PopupMenu(this, filterButton);
        menu.getMenu().add("সকল ইউনিয়ন");
        for (String union : unionNames) {
            menu.getMenu().add(union);
        }

        menu.setOnMenuItemClickListener(item -> {
            String title = item.getTitle().toString();
            currentUnionFilter = title.equals("সকল ইউনিয়ন") ? "" : title;
            loadClinicsFromApi();
            return true;
        });

        menu.show();
    }

    @Override
    public void onClinicClick(int position) {
        if (position >= 0 && position < filteredList.size()) {
            Clinic selectedClinic = filteredList.get(position);
            Intent intent = new Intent(this, ClinicOverviewActivity.class);
            intent.putExtra("clinic", selectedClinic);
            startActivity(intent);
        }
    }
}