package com.example.betagiesheva;

import static com.example.betagiesheva.Config.BASE_URL;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
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
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Adapter.UnifiedSpecialistDoctorAdapter;
import com.example.betagiesheva.Model.UnifiedSpecialistDoctor;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class UnifiedSpecialistDoctorActivity extends AppCompatActivity
        implements UnifiedSpecialistDoctorAdapter.OnDoctorClickListener {

    private static final long SEARCH_DEBOUNCE_MS = 300;

    public static final String EXTRA_SPECIALIST_TYPE = "specialistType";
    public static final String EXTRA_DISPLAY_NAME = "displayName";

    RecyclerView recyclerView;
    EditText etSearch;
    LottieAnimationView progress;
    TextView noDataText;
    ImageView backButton;
    ImageButton filterMenu;
    FloatingActionButton fabAdd;

    UnifiedSpecialistDoctorAdapter adapter;
    ArrayList<UnifiedSpecialistDoctor> doctorList = new ArrayList<>();

    String specialistType = "";
    String displayName = "";
    String currentSearch = "";
    String currentUnionFilter = "";

    private SessionManager sessionManager;
    private Handler searchHandler = new Handler();
    private Runnable searchRunnable;

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
        setContentView(R.layout.activity_unified_specialist_doctor);

        specialistType = getIntent().getStringExtra(EXTRA_SPECIALIST_TYPE);
        displayName = getIntent().getStringExtra(EXTRA_DISPLAY_NAME);

        if (specialistType == null || specialistType.isEmpty()) {
            specialistType = "general";
        }

        if (displayName != null) {
            setTitle(displayName);
        }

        init();
        setupRecycler();
        setupSearch();
        setupFilterMenu();
        setupBackButton();
        setupFabVisibility();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadDoctorsFromServer();
    }

    private void init() {
        recyclerView = findViewById(R.id.recycler_view);
        etSearch = findViewById(R.id.et_search);
        progress = findViewById(R.id.progress);
        noDataText = findViewById(R.id.no_data_text);
        backButton = findViewById(R.id.back);
        filterMenu = findViewById(R.id.filter_menu);
        fabAdd = findViewById(R.id.fab_add);
    }

    private void setupRecycler() {
        adapter = new UnifiedSpecialistDoctorAdapter(this, doctorList, this);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);
    }

    private void setupSearch() {
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void afterTextChanged(Editable s) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearch = s.toString().trim();

                if (searchRunnable != null) {
                    searchHandler.removeCallbacks(searchRunnable);
                }

                searchRunnable = () -> loadDoctorsFromServer();
                searchHandler.postDelayed(searchRunnable, SEARCH_DEBOUNCE_MS);
            }
        });
    }

    private void setupBackButton() {
        backButton.setOnClickListener(v -> finish());
    }

    private void setupFilterMenu() {
        filterMenu.setOnClickListener(v -> {
            PopupMenu menu = new PopupMenu(this, filterMenu);
            menu.getMenu().add("সকল ইউনিয়ন");
            for (String union : unionNames) {
                menu.getMenu().add(union);
            }

            menu.setOnMenuItemClickListener(item -> {
                String title = item.getTitle().toString();
                currentUnionFilter = title.equals("সকল ইউনিয়ন") ? "" : title;
                loadDoctorsFromServer();
                return true;
            });

            menu.show();
        });
    }

    private void setupFabVisibility() {
        sessionManager = new SessionManager(this);
        String userType = sessionManager.getUserType();
        if ("Admin".equalsIgnoreCase(userType)) {
            fabAdd.setVisibility(View.VISIBLE);
            fabAdd.setOnClickListener(v -> {
                Intent intent = new Intent(UnifiedSpecialistDoctorActivity.this, AddUnifiedSpecialistDoctorActivity.class);
                // Pass doctor type via intent
                intent.putExtra("doctor_type", specialistType);
                intent.putExtra(EXTRA_SPECIALIST_TYPE, specialistType);
                intent.putExtra(EXTRA_DISPLAY_NAME, displayName);
                startActivity(intent);
            });
        } else {
            fabAdd.setVisibility(View.GONE);
        }
    }

    private void loadDoctorsFromServer() {
        showLoading(true);

        android.net.Uri.Builder builder = android.net.Uri.parse(BASE_URL + "get_specialist_doctor.php").buildUpon();
        if (!specialistType.isEmpty()) builder.appendQueryParameter("doctor_type", specialistType);
        if (!currentUnionFilter.isEmpty()) builder.appendQueryParameter("union_name", currentUnionFilter);
        if (!currentSearch.isEmpty()) builder.appendQueryParameter("search", currentSearch);

        String url = builder.build().toString();

        StringRequest request = new StringRequest(Request.Method.GET, url,
                response -> {
                    try {
                        JSONArray arr = new JSONArray(response);
                        doctorList.clear();

                        for (int i = 0; i < arr.length(); i++) {
                            JSONObject o = arr.getJSONObject(i);

                            UnifiedSpecialistDoctor d = new UnifiedSpecialistDoctor();
                            d.setId(o.optString("id", ""));
                            d.setName(o.optString("name", "নাম পাওয়া যায়নি"));
                            d.setSpecialization(o.optString("specialization", "তথ্য নেই"));
                            d.setQualifications(o.optString("qualifications", "তথ্য নেই"));
                            d.setWorkplace(o.optString("workplace", "তথ্য নেই"));
                            d.setChamber(o.optString("chamber", "তথ্য নেই"));
                            d.setVisitingHours(o.optString("visiting_hours", "তথ্য নেই"));
                            d.setPhoneNumber(o.optString("phone", ""));
                            d.setDoctorType(o.optString("doctor_type", ""));
                            d.setUnion(o.optString("union_name", ""));
                            d.setImageUrl(o.optString("image", ""));

                            doctorList.add(d);
                        }

                        updateUI();
                    } catch (Exception e) {
                        e.printStackTrace();
                        showError("ডাটা লোড ব্যর্থ");
                    }
                    showLoading(false);
                },
                error -> {
                    error.printStackTrace();
                    showError("সার্ভার সমস্যা");
                    showLoading(false);
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                Map<String, String> headers = new HashMap<>();
                headers.put("Accept-Charset", "UTF-8");
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

    private void updateUI() {
        adapter.notifyDataSetChanged();
        if (doctorList.isEmpty()) {
            noDataText.setVisibility(View.VISIBLE);
            recyclerView.setVisibility(View.GONE);
        } else {
            noDataText.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);
        }
    }

    private void showError(String msg) {
        noDataText.setText(msg);
        noDataText.setVisibility(View.VISIBLE);
        recyclerView.setVisibility(View.GONE);
        showLoading(false);
    }

    private void showLoading(boolean show) {
        progress.setVisibility(show ? View.VISIBLE : View.GONE);
    }

    @Override
    public void onCallButtonClick(UnifiedSpecialistDoctor doctor) {
        if (doctor.getPhoneNumber() != null && !doctor.getPhoneNumber().isEmpty()) {
            Intent intent = new Intent(Intent.ACTION_DIAL);
            intent.setData(Uri.parse("tel:" + doctor.getPhoneNumber()));
            startActivity(intent);
        } else {
            Toast.makeText(this, "ডাক্তারের ফোন নাম্বার পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    public void onDetailsButtonClick(UnifiedSpecialistDoctor doctor) {
        showDoctorDetailsDialog(doctor);
    }

    private void showDoctorDetailsDialog(UnifiedSpecialistDoctor doctor) {
        androidx.appcompat.app.AlertDialog.Builder builder = new androidx.appcompat.app.AlertDialog.Builder(this);
        View dialogView = getLayoutInflater().inflate(R.layout.custom_dialog_unified_specialist_doctor, null);

        TextView nameTextView = dialogView.findViewById(R.id.doctor_name);
        TextView specializationTextView = dialogView.findViewById(R.id.doctor_specialization);
        TextView qualificationsTextView = dialogView.findViewById(R.id.doctor_qualifications);
        TextView workplaceTextView = dialogView.findViewById(R.id.doctor_workplace);
        TextView chamberTextView = dialogView.findViewById(R.id.doctor_chamber);
        TextView visitingTextView = dialogView.findViewById(R.id.doctor_visiting);

        nameTextView.setText(doctor.getName());
        specializationTextView.setText(doctor.getSpecialization());
        qualificationsTextView.setText(doctor.getQualifications());
        workplaceTextView.setText(doctor.getWorkplace());
        chamberTextView.setText(doctor.getChamber());
        visitingTextView.setText(doctor.getVisitingHours());

        android.widget.Button closeButton = dialogView.findViewById(R.id.btn_close);
        android.widget.Button serialButton = dialogView.findViewById(R.id.btn_serial);

        androidx.appcompat.app.AlertDialog dialog = builder.setView(dialogView).create();
        dialog.show();

        closeButton.setOnClickListener(v -> dialog.dismiss());
        serialButton.setOnClickListener(v -> onCallButtonClick(doctor));
    }

    @Override
    public boolean onSupportNavigateUp() {
        onBackPressed();
        return true;
    }
}