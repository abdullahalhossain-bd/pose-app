package com.example.betagiesheva;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager2.widget.ViewPager2;

import com.example.betagiesheva.Adapter.JulyAdapter;
import com.google.android.material.tabs.TabLayout;

/* loaded from: classes4.dex */
public class JulyActivity extends AppCompatActivity {
    JulyAdapter julyAdapter;
    private TabLayout tabLayout;
    private ViewPager2 viewPager2;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_july);
        this.tabLayout = (TabLayout) findViewById(R.id.tab_layout);
        this.viewPager2 = (ViewPager2) findViewById(R.id.view_pager);
        this.julyAdapter = new JulyAdapter(this);
        this.viewPager2.setAdapter(this.julyAdapter);
        this.tabLayout.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() { // from class: com.example.betagieseva.JulyActivity.1
            @Override // com.google.android.material.tabs.TabLayout.BaseOnTabSelectedListener
            public void onTabSelected(TabLayout.Tab tab) {
                JulyActivity.this.viewPager2.setCurrentItem(tab.getPosition());
            }

            @Override // com.google.android.material.tabs.TabLayout.BaseOnTabSelectedListener
            public void onTabUnselected(TabLayout.Tab tab) {
            }

            @Override // com.google.android.material.tabs.TabLayout.BaseOnTabSelectedListener
            public void onTabReselected(TabLayout.Tab tab) {
            }
        });
        this.viewPager2.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() { // from class: com.example.betagieseva.JulyActivity.2
            @Override // androidx.viewpager2.widget.ViewPager2.OnPageChangeCallback
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                JulyActivity.this.tabLayout.getTabAt(position).select();
            }
        });
    }
}
