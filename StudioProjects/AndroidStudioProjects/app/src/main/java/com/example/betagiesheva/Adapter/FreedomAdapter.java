package com.example.betagiesheva.Adapter;


import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.example.betagiesheva.Fragment.FreedomFragment;
import com.example.betagiesheva.Fragment.PdfFragment;


/* loaded from: classes4.dex */
public class FreedomAdapter extends FragmentStateAdapter {
    public FreedomAdapter(FragmentActivity fragmentActivity) {
        super(fragmentActivity);
    }

    @Override // androidx.viewpager2.adapter.FragmentStateAdapter
    public Fragment createFragment(int position) {
        switch (position) {
            case 0:
                return new FreedomFragment();
            case 1:
                return new PdfFragment();
            default:
                return new FreedomFragment();
        }
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public int getItemCount() {
        return 2;
    }
}
