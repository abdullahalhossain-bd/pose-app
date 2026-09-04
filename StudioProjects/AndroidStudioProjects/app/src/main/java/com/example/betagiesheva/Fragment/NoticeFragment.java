package com.example.betagiesheva.Fragment;

import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.PopupMenu;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.android.volley.Request;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonArrayRequest;
import com.example.betagiesheva.Adapter.NoticeAdapter;
import com.example.betagiesheva.AddNoticeActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.NoticeModel;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.google.android.material.chip.Chip;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import android.content.Intent;

import org.json.JSONObject;

import java.util.ArrayList;

public class NoticeFragment extends Fragment {

    RecyclerView recyclerView;
    SwipeRefreshLayout swipeRefresh;
    EditText searchEditText;
    LinearLayout emptyState;
    ImageButton filterMenu;
    FloatingActionButton addNoticeFab;

    ArrayList<NoticeModel> noticeList = new ArrayList<>();
    NoticeAdapter adapter;

    String currentType = "";
    String currentSearch = "";
    String selectedUnion = "";

    private final String[] unionNames = {
            "বিবিচিনি ইউনিয়ন পরিষদ",
            "বেতাগী সদর ইউনিয়ন পরিষদ",
            "হোসনাবাদ ইউনিয়ন পরিষদ",
            "মোকামিয়া ইউনিয়ন পরিষদ",
            "বুড়ামজুমদার ইউনিয়ন পরিষদ",
            "কাজীরাবাদ ইউনিয়ন পরিষদ",
            "সরিষামুড়ি ইউনিয়ন পরিষদ"
    };

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {

        View view = inflater.inflate(R.layout.fragment_notice, container, false);

        recyclerView = view.findViewById(R.id.noticeRecyclerView);
        swipeRefresh = view.findViewById(R.id.swipeRefreshLayout);
        searchEditText = view.findViewById(R.id.searchEditText);
        emptyState = view.findViewById(R.id.emptyStateLayout);
        filterMenu = view.findViewById(R.id.filter_menu);
        addNoticeFab = view.findViewById(R.id.addNoticeFab);

        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        adapter = new NoticeAdapter(getContext(), noticeList, model -> {
            NoticeDetailsFragment fragment = NoticeDetailsFragment.newInstance(model);
            requireActivity().getSupportFragmentManager()
                    .beginTransaction()
                    .replace(R.id.fragment_container, fragment)
                    .addToBackStack(null)
                    .commit();
        });

        recyclerView.setAdapter(adapter);

        loadNotices();

        swipeRefresh.setOnRefreshListener(this::loadNotices);

        searchEditText.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearch = s.toString().trim();
                loadNotices();
            }
            @Override public void afterTextChanged(Editable s) {}
        });

        setupChips(view);
        setupFilterMenu();
        setupAddNoticeFab();

        return view;
    }

    private void setupChips(View view) {
        Chip chipAll = view.findViewById(R.id.chipAll);
        Chip chipImportant = view.findViewById(R.id.chipImportant);
        Chip chipGeneral = view.findViewById(R.id.chipGeneral);
        Chip chipEvent = view.findViewById(R.id.chipEvent);
        Chip chipHoliday = view.findViewById(R.id.chipHoliday);

        chipAll.setOnClickListener(v -> applyFilter(""));
        chipImportant.setOnClickListener(v -> applyFilter("গুরুত্বপূর্ণ"));
        chipGeneral.setOnClickListener(v -> applyFilter("সাধারণ"));
        chipEvent.setOnClickListener(v -> applyFilter("ইভেন্ট"));
        chipHoliday.setOnClickListener(v -> applyFilter("ছুটি"));
    }

    private void applyFilter(String type) {
        currentType = type;
        loadNotices();
    }

    private void setupFilterMenu() {
        if (filterMenu == null) return;

        filterMenu.setOnClickListener(v -> {
            PopupMenu menu = new PopupMenu(requireContext(), filterMenu);
            menu.getMenu().add("সকল ইউনিয়ন");
            for (String union : unionNames) {
                menu.getMenu().add(union);
            }

            menu.setOnMenuItemClickListener(item -> {
                String title = item.getTitle().toString();
                selectedUnion = title.equals("সকল ইউনিয়ন") ? "" : title;
                loadNotices();
                return true;
            });

            menu.show();
        });
    }

    private void loadNotices() {

        swipeRefresh.setRefreshing(true);

        // Server's get_notice.php only supports ?type= filter.
        // The notices table has NO union_name column, and the server doesn't
        // accept ?search= — so we drop those params and filter search client-side
        // after the list is loaded.
        Uri.Builder builder = Uri.parse(Config.NOTICE_LIST_URL).buildUpon();
        if (!currentType.isEmpty()) {
            builder.appendQueryParameter("type", currentType);
        }

        String url = builder.build().toString();

        JsonArrayRequest request = new JsonArrayRequest(
                Request.Method.GET,
                url,
                null,
                response -> {
                    noticeList.clear();
                    try {
                        for (int i = 0; i < response.length(); i++) {
                            JSONObject o = response.getJSONObject(i);

                            String date = o.optString("date_published");
                            if (date.isEmpty()) {
                                date = o.optString("notice_date");
                            }

                            // Ensure type has a default value
                            String type = o.optString("type");
                            if (TextUtils.isEmpty(type)) {
                                type = "সাধারণ"; // Default type if not provided
                            }

                            String title    = o.optString("title");
                            String desc     = o.optString("description");
                            String dept     = o.optString("department");

                            // Client-side search filter (server doesn't support ?search=)
                            if (!currentSearch.isEmpty()) {
                                String q = currentSearch.toLowerCase();
                                if (!title.toLowerCase().contains(q)
                                        && !desc.toLowerCase().contains(q)
                                        && !dept.toLowerCase().contains(q)) {
                                    continue;
                                }
                            }

                            NoticeModel notice = new NoticeModel(
                                    o.optString("id"),
                                    title,
                                    desc,
                                    type,
                                    date,
                                    dept,
                                    o.optString("image_url"),
                                    o.optInt("attachment_count")
                            );
                            notice.setAttachmentUrl(o.optString("attachment_url"));
                            noticeList.add(notice);
                        }
                        adapter.notifyDataSetChanged();
                        emptyState.setVisibility(noticeList.isEmpty() ? View.VISIBLE : View.GONE);
                    } catch (Exception e) {
                        e.printStackTrace();
                        Toast.makeText(getContext(), "Error parsing notices: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                        emptyState.setVisibility(View.VISIBLE);
                    }

                    swipeRefresh.setRefreshing(false);
                },
                error -> {
                    swipeRefresh.setRefreshing(false);
                    handleVolleyError(error);
                    emptyState.setVisibility(View.VISIBLE);
                }
        );

        Config.getInstance(getContext()).addToRequestQueue(request);
    }

    private void handleVolleyError(VolleyError error) {
        String errorMessage = "Unknown error";
        if (error == null) {
            errorMessage = "No error message";
        } else if (error.networkResponse != null) {
            errorMessage = "Server error: " + error.networkResponse.statusCode;
        } else if (error.getMessage() != null) {
            errorMessage = error.getMessage();
        }
        Toast.makeText(getContext(), "Failed to load notices: " + errorMessage, Toast.LENGTH_SHORT).show();
    }

    private void setupAddNoticeFab() {
        if (addNoticeFab == null) return;

        // Only show FAB for admins
        SessionManager sessionManager = new SessionManager(requireContext());
        String userType = sessionManager.getUserType();

        if ("Admin".equalsIgnoreCase(userType)) {
            addNoticeFab.setVisibility(View.VISIBLE);
            addNoticeFab.setOnClickListener(v -> {
                Intent intent = new Intent(requireContext(), AddNoticeActivity.class);
                startActivity(intent);
            });
        } else {
            addNoticeFab.setVisibility(View.GONE);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        // Reload notices when returning to fragment
        loadNotices();
    }
}