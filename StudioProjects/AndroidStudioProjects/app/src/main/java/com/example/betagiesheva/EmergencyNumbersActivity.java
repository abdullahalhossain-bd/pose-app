package com.example.betagiesheva;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.example.betagiesheva.Adapter.EmergencyAdapter;
import com.example.betagiesheva.Model.EmergencyNumber;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * Emergency Numbers screen.
 *
 * Tries to fetch the live list from {@code Config.GET_EMERGENCY_NUMBERS_URL}
 * (server's get_emergency_numbers.php — created in Phase 6). If the endpoint
 * is missing (404) or returns an empty list, falls back to the hardcoded
 * Betagi seed list (matches schema.sql).
 *
 * The EmergencyNumber model now lives in {@code com.example.betagiesheva.Model}
 * (was previously {@code com.myapp.sirajganjcity.Models} — template leftover).
 */
public class EmergencyNumbersActivity extends AppCompatActivity {

    private EmergencyAdapter adapter;
    private List<EmergencyNumber> emergencyList;
    private RecyclerView recyclerView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_emergency_numbers);

        this.recyclerView = (RecyclerView) findViewById(R.id.recycler_view_emergency);
        this.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        this.emergencyList = new ArrayList<>();
        this.adapter = new EmergencyAdapter(this.emergencyList, this);
        this.recyclerView.setAdapter(this.adapter);

        loadEmergencyNumbers();
    }

    /**
     * Try the server first; on any failure or empty response, fall back to the
     * hardcoded Betagi seed list (matches schema.sql).
     */
    private void loadEmergencyNumbers() {
        StringRequest request = new StringRequest(
                Request.Method.GET,
                Config.GET_EMERGENCY_NUMBERS_URL,
                response -> {
                    try {
                        JSONObject json = new JSONObject(response);
                        JSONArray data = json.optJSONArray("data");
                        if (data != null && data.length() > 0) {
                            emergencyList.clear();
                            for (int i = 0; i < data.length(); i++) {
                                JSONObject obj = data.getJSONObject(i);
                                emergencyList.add(new EmergencyNumber(
                                        obj.optString("name", ""),
                                        obj.optString("number", ""),
                                        obj.optString("type", "")
                                ));
                            }
                            adapter.notifyDataSetChanged();
                            return;
                        }
                    } catch (Exception ignored) {
                    }
                    // Empty or malformed → fall back
                    showFallbackList();
                },
                error -> {
                    // 404 / network error → fall back
                    showFallbackList();
                }
        );

        RequestQueue queue = Volley.newRequestQueue(this);
        queue.add(request);
    }

    /**
     * Hardcoded Betagi seed list — matches the INSERTs in schema.sql so the
     * screen always shows useful numbers even if the server endpoint is missing.
     */
    private void showFallbackList() {
        if (!emergencyList.isEmpty()) return; // already populated from server
        emergencyList.add(new EmergencyNumber("বেতাগী থানা", "01769-690062", "পুলিশ"));
        emergencyList.add(new EmergencyNumber("ফায়ার সার্ভিস", "16163", "ফায়ার সার্ভিস"));
        emergencyList.add(new EmergencyNumber("উপজেলা স্বাস্থ্য কমপ্লেক্স", "0445456080", "হাসপাতাল"));
        emergencyList.add(new EmergencyNumber("অ্যাম্বুলেন্স", "01711-000999", "অ্যাম্বুলেন্স"));
        emergencyList.add(new EmergencyNumber("জাতীয় জরুরি সেবা", "999", "জাতীয়"));
        adapter.notifyDataSetChanged();
    }
}
