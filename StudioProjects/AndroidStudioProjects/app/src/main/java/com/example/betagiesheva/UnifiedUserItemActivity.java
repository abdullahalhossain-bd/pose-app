package com.example.betagiesheva;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.PopupMenu;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.RetryPolicy;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.Adapter.UnifiedUserItemAdapter;
import com.example.betagiesheva.Model.UnifiedPerson;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class UnifiedUserItemActivity extends AppCompatActivity {

    private static final String TAG = "UnifiedUserItemActivity";
    private static final long SEARCH_DEBOUNCE_MS = 300;
    private static final int PAGE_SIZE = 20;

    // UI
    RecyclerView recyclerView;
    UnifiedUserItemAdapter adapter;
    LinearLayoutManager layoutManager;
    LottieAnimationView lottieLoading;
    TextView tvNoData;
    EditText etSearch;
    ImageButton backButton, filterMenu;
    Button btnFilterUnion;
    CardView addCard;

    // Data
    String userType = "";
    String displayName = "";

    List<UnifiedPerson> allUsersList = new ArrayList<>();
    List<UnifiedPerson> filteredUsersList = new ArrayList<>();
    int currentOffset = 0;
    boolean isLoading = false;
    boolean isLastPage = false;

    String currentSearch = "";
    String currentUnionFilter = "";

    Handler searchHandler = new Handler(Looper.getMainLooper());
    Runnable searchRunnable;

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
        setContentView(R.layout.activity_unified_user_item);

        userType = getIntent().getStringExtra("userType");
        displayName = getIntent().getStringExtra("displayName");

        if (userType == null || userType.isEmpty()) {
            Toast.makeText(this, "Invalid user type", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        if (displayName != null) {
            setTitle(displayName);
        }

        initViews();
        setupRecycler();
        setupSearch();
        setupFilterMenu();
        setupUnionFilter();
        setupBack();
        setupAddButton();
    }

    @Override
    protected void onResume() {
        super.onResume();
        resetAndLoad();
    }

    private void initViews() {
        recyclerView = findViewById(R.id.recycler_view);
        lottieLoading = findViewById(R.id.progress);
        tvNoData = findViewById(R.id.no_data_text);
        etSearch = findViewById(R.id.et_search);
        backButton = findViewById(R.id.back_button);
        filterMenu = findViewById(R.id.filter_menu);
        btnFilterUnion = findViewById(R.id.btn_filter_union);
        addCard = findViewById(R.id.add);
    }

    private void setupRecycler() {
        layoutManager = new LinearLayoutManager(this);
        adapter = new UnifiedUserItemAdapter(this, new ArrayList<>());
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.setAdapter(adapter);
        recyclerView.addOnScrollListener(new PaginationScrollListener());
    }

    private void setupSearch() {
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {}

            @Override
            public void afterTextChanged(Editable s) {
                if (searchRunnable != null)
                    searchHandler.removeCallbacks(searchRunnable);

                searchRunnable = () -> {
                    currentSearch = s.toString().trim();
                    resetAndLoad();
                };

                searchHandler.postDelayed(searchRunnable, SEARCH_DEBOUNCE_MS);
            }
        });

        etSearch.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                if (searchRunnable != null) searchRunnable.run();
                return true;
            }
            return false;
        });
    }

    private void setupFilterMenu() {
        filterMenu.setOnClickListener(v -> {
            PopupMenu menu = new PopupMenu(this, v);
            menu.getMenu().add("সকল ইউনিয়ন");
            menu.getMenu().add("বিবিচিনি ইউনিয়ন পরিষদ");
            menu.getMenu().add("বেতাগী সদর ইউনিয়ন পরিষদ");
            menu.getMenu().add("হোসনাবাদ ইউনিয়ন পরিষদ");
            menu.getMenu().add("মোকামিয়া ইউনিয়ন পরিষদ");
            menu.getMenu().add("বুড়ামজুমদার ইউনিয়ন পরিষদ");
            menu.getMenu().add("কাজিরাবাদ ইউনিয়ন পরিষদ");
            menu.getMenu().add("সরিষামুড়ি ইউনিয়ন পরিষদ");

            menu.setOnMenuItemClickListener(item -> {
                String title = item.getTitle().toString();
                currentUnionFilter = title.equals("সকল ইউনিয়ন") ? "" : title;

                // Update button text to show current filter
                if (currentUnionFilter.isEmpty()) {
                    btnFilterUnion.setText("ইউনিয়ন");
                } else {
                    btnFilterUnion.setText(currentUnionFilter.length() > 15 ?
                            currentUnionFilter.substring(0, 15) + "..." : currentUnionFilter);
                }

                resetAndLoad();
                return true;
            });

            menu.show();
        });
    }

    private void setupUnionFilter() {
        btnFilterUnion.setOnClickListener(v -> {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle("ইউনিয়ন নির্বাচন করুন");

            List<String> list = new ArrayList<>();
            list.add("সকল ইউনিয়ন");
            for (String u : unionNames) list.add(u);

            String[] unions = list.toArray(new String[0]);

            // Find current selection index
            int selectedIndex = 0;
            if (!currentUnionFilter.isEmpty()) {
                for (int i = 0; i < unions.length; i++) {
                    if (unions[i].equals(currentUnionFilter)) {
                        selectedIndex = i;
                        break;
                    }
                }
            }

            builder.setSingleChoiceItems(unions, selectedIndex, (dialog, which) -> {
                currentUnionFilter = which == 0 ? "" : unions[which];

                // Update button text to show current filter
                if (currentUnionFilter.isEmpty()) {
                    btnFilterUnion.setText("ইউনিয়ন");
                } else {
                    btnFilterUnion.setText(currentUnionFilter.length() > 15 ?
                            currentUnionFilter.substring(0, 15) + "..." : currentUnionFilter);
                }

                dialog.dismiss();
                resetAndLoad();
            });

            builder.setNegativeButton("বাতিল", null);
            builder.show();
        });
    }

    private void setupBack() {
        backButton.setOnClickListener(v -> finish());
    }

    private void setupAddButton() {
        addCard.setOnClickListener(v -> {
            Intent intent = new Intent(UnifiedUserItemActivity.this, AddUnifiedPersonActivity.class);
            intent.putExtra("personType", userType);
            intent.putExtra("displayName", displayName);
            startActivity(intent);
        });
    }

    private void resetAndLoad() {
        currentOffset = 0;
        allUsersList.clear();
        filteredUsersList.clear();
        adapter.clear();
        isLastPage = false;
        loadPage(0);
    }

    private void loadPage(int offset) {
        if (isLoading || isLastPage) return;

        isLoading = true;
        showLoading(true);

        // Build URL with parameters
        String url = Config.GET_UNIFIED_PERSON_URL + "?type=" + userType;

        StringRequest request = new StringRequest(
                Request.Method.GET,
                url,
                response -> {
                    try {
                        JSONArray array = new JSONArray(response);
                        allUsersList.clear();

                        if (array.length() == 0) {
                            showNoData(true);
                            isLoading = false;
                            showLoading(false);
                            return;
                        }

                        for (int i = 0; i < array.length(); i++) {
                            JSONObject obj = array.getJSONObject(i);

                            UnifiedPerson person = new UnifiedPerson(
                                    obj.optString("id"),
                                    obj.optString("name"),
                                    obj.optString("phone"),
                                    obj.optString("address"),
                                    obj.optString("union_name"),
                                    obj.optString("image_url"),
                                    obj.optString("person_type")
                            );
                            allUsersList.add(person);
                        }

                        applyFiltersAndDisplay();

                    } catch (JSONException e) {
                        e.printStackTrace();
                        Toast.makeText(this, "Data parse error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                    isLoading = false;
                    showLoading(false);
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(this, "Server error: " + error.getMessage(), Toast.LENGTH_SHORT).show();
                    isLoading = false;
                    showLoading(false);
                }
        ) {
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

            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                Map<String, String> headers = new HashMap<>();
                headers.put("Accept-Charset", "UTF-8");
                headers.put("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                return headers;
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(this).addToRequestQueue(request);
    }

    private void applyFiltersAndDisplay() {
        filteredUsersList.clear();

        // Debug log
        Log.d(TAG, "Applying filters - Search: '" + currentSearch + "', Union: '" + currentUnionFilter + "'");

        for (UnifiedPerson person : allUsersList) {
            boolean matchSearch = currentSearch.isEmpty()
                    || (person.getName() != null && person.getName().toLowerCase().contains(currentSearch.toLowerCase()))
                    || (person.getAddress() != null && person.getAddress().toLowerCase().contains(currentSearch.toLowerCase()));

            boolean matchUnion = currentUnionFilter.isEmpty()
                    || (person.getUnion() != null && person.getUnion().equals(currentUnionFilter));

            // Debug log for each person
            Log.d(TAG, "Person: " + person.getName() +
                    ", Union: " + person.getUnion() +
                    ", MatchUnion: " + matchUnion);

            if (matchSearch && matchUnion) {
                filteredUsersList.add(person);
            }
        }

        Log.d(TAG, "Filtered list size: " + filteredUsersList.size());

        // Apply pagination
        int end = Math.min(currentOffset + PAGE_SIZE, filteredUsersList.size());
        List<UnifiedPerson> page = currentOffset < filteredUsersList.size()
                ? filteredUsersList.subList(currentOffset, end)
                : new ArrayList<>();

        if (currentOffset == 0) {
            adapter.updateList(page);
        } else {
            adapter.addItems(page);
        }

        if (end >= filteredUsersList.size()) {
            isLastPage = true;
        }

        showNoData(adapter.getItemCount() == 0);
    }

    private void showLoading(boolean show) {
        lottieLoading.setVisibility(show ? View.VISIBLE : View.GONE);
        if (!show && adapter.getItemCount() > 0) {
            recyclerView.setVisibility(View.VISIBLE);
        }
    }

    private void showNoData(boolean show) {
        tvNoData.setVisibility(show ? View.VISIBLE : View.GONE);
        recyclerView.setVisibility(show ? View.GONE : View.VISIBLE);
    }

    class PaginationScrollListener extends RecyclerView.OnScrollListener {
        @Override
        public void onScrolled(RecyclerView rv, int dx, int dy) {
            int visible = layoutManager.getChildCount();
            int total = layoutManager.getItemCount();
            int first = layoutManager.findFirstVisibleItemPosition();

            if (!isLoading && !isLastPage) {
                if (visible + first >= total && first >= 0) {
                    currentOffset += PAGE_SIZE;
                    applyFiltersAndDisplay();
                }
            }
        }
    }
}