package com.example.betagiesheva.Adapter;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.example.betagiesheva.Fragment.JulyhFragment;
import com.example.betagiesheva.Fragment.JulyheroFragment;
import com.example.betagiesheva.Fragment.PdfFragment;

/* loaded from: classes4.dex */
public class JulyAdapter extends FragmentStateAdapter {
    public JulyAdapter(FragmentActivity fragmentActivity) {
        super(fragmentActivity);
    }

    @Override // androidx.viewpager2.adapter.FragmentStateAdapter
    public Fragment createFragment(int position) {
        switch (position) {
            case 0:
                return new JulyheroFragment();
            case 1:
                return new JulyheroFragment();
            case 2:
                return new JulyhFragment();
            default:
                return new JulyheroFragment();
        }
    }

    @Override // androidx.recyclerview.widget.RecyclerView.Adapter
    public int getItemCount() {
        return 4;
    }
}
