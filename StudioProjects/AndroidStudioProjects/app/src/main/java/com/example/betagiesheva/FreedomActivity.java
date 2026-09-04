package com.example.betagiesheva;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager2.widget.ViewPager2;

import com.example.betagiesheva.Adapter.FreedomAdapter;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

/* loaded from: classes4.dex */
public class FreedomActivity extends AppCompatActivity {
    FloatingActionButton fab;
private FreedomAdapter freedomAdapter;
    private TabLayout tabLayout;
    private ViewPager2 viewPager2;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_freedom);
        this.tabLayout = (TabLayout) findViewById(R.id.tab_layout);
        this.viewPager2 = (ViewPager2) findViewById(R.id.view_pager);
        this.freedomAdapter = new FreedomAdapter(this);
        this.viewPager2.setAdapter(this.freedomAdapter);
        
        new TabLayoutMediator(this.tabLayout, this.viewPager2, (tab, position) -> {
            switch (position) {
                case 0:
                    tab.setText("মুক্তিযুদ্ধের ইতিহাস");
                    break;
                case 1:
                    tab.setText("মুক্তিযোদ্ধাদের তালিকা");
                    break;
            }
        }).attach();
    }
}
