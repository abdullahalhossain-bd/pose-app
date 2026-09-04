package com.example.betagiesheva;

import android.graphics.Typeface;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.res.ResourcesCompat;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.PolygonOptions;

public class UpazilaInfoActivity extends AppCompatActivity implements OnMapReadyCallback {
    private GoogleMap mMap;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_upazila_info);

        // Set up back button
        ImageView backButton = findViewById(R.id.back);
        backButton.setOnClickListener(v -> onBackPressed());

        // Set Kalpurush font for all TextViews
        setFontForAllTextViews((ViewGroup) findViewById(android.R.id.content).getRootView());

        // Initialize map
        SupportMapFragment mapFragment = (SupportMapFragment) getSupportFragmentManager()
                .findFragmentById(R.id.map);
        if (mapFragment != null) {
            mapFragment.getMapAsync(this);
        }
    }

    private void setFontForAllTextViews(ViewGroup viewGroup) {
        for (int i = 0; i < viewGroup.getChildCount(); i++) {
            View child = viewGroup.getChildAt(i);
            if (child instanceof TextView) {
                TextView textView = (TextView) child;
                Typeface kalpurush = ResourcesCompat.getFont(this, R.font.kalpurush);
                textView.setTypeface(kalpurush);
            } else if (child instanceof ViewGroup) {
                setFontForAllTextViews((ViewGroup) child);
            }
        }
    }

    @Override
    public void onMapReady(GoogleMap googleMap) {
        mMap = googleMap;

        LatLng betagiCenter = new LatLng(22.4167, 90.1667);
        mMap.addMarker(new MarkerOptions()
                .position(betagiCenter)
                .title("বেতাগী উপজেলা")
                .snippet("Betagi Upazila"));

        PolygonOptions polygonOptions = new PolygonOptions()
                .add(new LatLng(22.4367, 90.1467))
                .add(new LatLng(22.4367, 90.1867))
                .add(new LatLng(22.3967, 90.1867))
                .add(new LatLng(22.3967, 90.1467))
                .add(new LatLng(22.4367, 90.1467))
                .strokeWidth(2.0f)
                .strokeColor(-14765647)
                .fillColor(857649585);

        mMap.addPolygon(polygonOptions);
        mMap.getUiSettings().setZoomControlsEnabled(true);
        mMap.getUiSettings().setCompassEnabled(true);
        mMap.getUiSettings().setMapToolbarEnabled(true);
        mMap.moveCamera(CameraUpdateFactory.newLatLngZoom(betagiCenter, 12.0f));
        mMap.setMapType(4);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mMap != null) {
            mMap.clear();
            onMapReady(mMap);
        }
    }
}