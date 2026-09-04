package com.example.betagiesheva;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Notifications screen.
 *
 * Fetches the notification list from {@code Config.GET_NOTIFICATIONS_URL}
 * (server's get_notifications.php — to be created in Phase 6).
 *
 * Until that endpoint exists, every request will fail with VolleyError
 * (typically 404). In that case we just show the empty-state TextView
 * "কোনো নোটিফিকেশন নেই" so the screen degrades gracefully.
 */
public class NotifiationActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private TextView emptyStateText;
    private View loadingProgressBar;

    private final NotificationAdapter adapter = new NotificationAdapter(new ArrayList<>());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_notifiation);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        recyclerView = findViewById(R.id.notificationsRecyclerView);
        emptyStateText = findViewById(R.id.emptyStateText);
        loadingProgressBar = findViewById(R.id.loadingProgressBar);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        loadNotifications();
    }

    private void loadNotifications() {
        loadingProgressBar.setVisibility(View.VISIBLE);
        emptyStateText.setVisibility(View.GONE);

        StringRequest request = new StringRequest(
                Request.Method.GET,
                Config.GET_NOTIFICATIONS_URL,
                response -> {
                    loadingProgressBar.setVisibility(View.GONE);
                    try {
                        JSONObject json = new JSONObject(response);
                        JSONArray data = json.optJSONArray("data");
                        if (data != null && data.length() > 0) {
                            List<NotificationItem> items = new ArrayList<>();
                            for (int i = 0; i < data.length(); i++) {
                                JSONObject obj = data.getJSONObject(i);
                                items.add(new NotificationItem(
                                        obj.optString("title", ""),
                                        obj.optString("message", ""),
                                        obj.optString("created_at", "")
                                ));
                            }
                            adapter.setItems(items);
                            recyclerView.setVisibility(View.VISIBLE);
                            emptyStateText.setVisibility(View.GONE);
                            return;
                        }
                    } catch (Exception ignored) {
                    }
                    showEmptyState();
                },
                error -> {
                    // 404 / VolleyError until Phase 6 wires up get_notifications.php
                    loadingProgressBar.setVisibility(View.GONE);
                    showEmptyState();
                }
        );

        RequestQueue queue = Volley.newRequestQueue(this);
        queue.add(request);
    }

    private void showEmptyState() {
        recyclerView.setVisibility(View.GONE);
        emptyStateText.setVisibility(View.VISIBLE);
        emptyStateText.setText("কোনো নোটিফিকেশন নেই");
    }

    // ── Minimal inline model + adapter ───────────────────────────────────

    private static final class NotificationItem {
        final String title;
        final String message;
        final String date;

        NotificationItem(String title, String message, String date) {
            this.title = title;
            this.message = message;
            this.date = date;
        }
    }

    private static final class NotificationAdapter
            extends RecyclerView.Adapter<NotificationAdapter.VH> {

        private final List<NotificationItem> items;

        NotificationAdapter(List<NotificationItem> items) {
            this.items = items;
        }

        void setItems(List<NotificationItem> newItems) {
            items.clear();
            items.addAll(newItems);
            notifyDataSetChanged();
        }

        @NonNull
        @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(android.R.layout.simple_list_item_2, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH holder, int position) {
            NotificationItem item = items.get(position);
            // simple_list_item_2 has two built-in TextViews with ids text1 & text2
            TextView title = holder.itemView.findViewById(android.R.id.text1);
            TextView subtitle = holder.itemView.findViewById(android.R.id.text2);
            if (title != null) {
                title.setText(item.title.isEmpty() ? "নোটিফিকেশন" : item.title);
            }
            if (subtitle != null) {
                String combined = item.message;
                if (!item.date.isEmpty()) {
                    combined = (combined.isEmpty() ? "" : combined + "\n") + item.date;
                }
                subtitle.setText(combined);
            }
        }

        @Override
        public int getItemCount() {
            return items.size();
        }

        static final class VH extends RecyclerView.ViewHolder {
            VH(@NonNull View itemView) {
                super(itemView);
            }
        }
    }
}
