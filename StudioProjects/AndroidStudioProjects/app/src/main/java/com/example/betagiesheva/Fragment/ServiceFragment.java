package com.example.betagiesheva.Fragment;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.betagiesheva.Adapter.RecyclerAdapter;
import com.example.betagiesheva.Model.Item;
import com.example.betagiesheva.R;
import com.example.betagiesheva.UpdateProfileActivity;

import java.util.ArrayList;
import java.util.List;

public class ServiceFragment extends Fragment {
    private RecyclerView recyclerView;
    private RecyclerAdapter adapter;
    private List<Item> itemList;

    public ServiceFragment() {
        // Required empty public constructor
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_service, container, false);

        recyclerView = view.findViewById(R.id.recycleView);
        recyclerView.setLayoutManager(new GridLayoutManager(getContext(), 3));

        // Optional shortcut: allow user to go to profile update from the top strip
        View profileUpdate = view.findViewById(R.id.profileupdate);
        if (profileUpdate != null) {
            profileUpdate.setOnClickListener(v -> {
                Intent intent = new Intent(getActivity(), UpdateProfileActivity.class);
                startActivity(intent);
            });
        }

        // Prepare the data
        itemList = new ArrayList<>();

        // Health Services Cards
        itemList.add(new Item("হাসপাতাল", R.drawable.ic_hospital));
        itemList.add(new Item("ক্লিনিক", R.drawable.ic_clinic));
        itemList.add(new Item("উপজেলা ডাক্তার", R.drawable.upaziladoctor));
        itemList.add(new Item("ডাক্তার", R.drawable.doctor));
        itemList.add(new Item("পশু ডাক্তার", R.drawable.veterinarian));
        itemList.add(new Item("নার্স সেবা", R.drawable.nurse));
        itemList.add(new Item("ফার্মেসি", R.drawable.pharmacy));
        itemList.add(new Item("অ্যাম্বুলেন্স", R.drawable.ambulance));
        itemList.add(new Item("ব্লাড ডোনার", R.drawable.blood_donar));

        // All Services Cards - First Row
        itemList.add(new Item("দর্শনীয় স্থান", R.drawable.tourist));
        itemList.add(new Item("হোটেল", R.drawable.hotel));
        itemList.add(new Item("পত্রিকা", R.drawable.newspaper));

        // All Services Cards - Second Row
        itemList.add(new Item("উপজেলা তথ্য", R.drawable.upazilainfo));
        itemList.add(new Item("নার্সারি দোকান", R.drawable.nursey_dokan));
        itemList.add(new Item("কুরিয়ার সার্ভিস", R.drawable.ic_courier));

        // All Services Cards - Third Row
        itemList.add(new Item("পোষ্ট অফিস", R.drawable.post));
        itemList.add(new Item("শিক্ষা প্রতিষ্ঠান", R.drawable.educational));
        itemList.add(new Item("ব্যাংক", R.drawable.bank));

        // All Services Cards - Fourth Row
        itemList.add(new Item("রেস্টুরেন্ট", R.drawable.resturent));
        itemList.add(new Item("বিউটি পার্লার", R.drawable.parlour));
        itemList.add(new Item("প্রশিক্ষণ কেন্দ্র", R.drawable.ic_traning));


        // All Services Cards - Sixth Row
        itemList.add(new Item("বিয়ের ঘটক", R.drawable.gatok));
        itemList.add(new Item("পল্লি বিদ্যুৎ", R.drawable.elec));
        itemList.add(new Item("সাংবাদিক", R.drawable.journalist));

        // All Services Cards - Seventh Row
        itemList.add(new Item("দোকান-শোরুম", R.drawable.shop));
        itemList.add(new Item("বাস", R.drawable.bus));
        itemList.add(new Item("অনলাইন সার্ভিস", R.drawable.onlineservice));

        // All Services Cards - Eighth Row
        itemList.add(new Item("কোচিং সেন্টার", R.drawable.tution));
        itemList.add(new Item("দলিল লেখক", R.drawable.ic_writer));
        itemList.add(new Item("সার্ভেয়ার", R.drawable.ic_surveyor));

        // History Cards
        itemList.add(new Item("জুলাই বিপ্লব", R.drawable.abusayed));
        itemList.add(new Item("সকল সামরিক অভ্যুত্থান", R.drawable.soldier));
        itemList.add(new Item("মহান মুক্তিযুদ্ধ", R.drawable.war));

        // Mistri Services Cards - First Row
        itemList.add(new Item("কাঠের মিস্ত্রি", R.drawable.carpenter));
        itemList.add(new Item("রাজমিস্ত্রি", R.drawable.brilding));
        itemList.add(new Item("রং মিস্ত্রি", R.drawable.ic_painter));

        // Mistri Services Cards - Second Row
        itemList.add(new Item("গাড়ি মেকার", R.drawable.car));
        itemList.add(new Item("ইলেক্ট্রনিকাল মেকার", R.drawable.mobilemaker));
        itemList.add(new Item("দর্জি কারিগর", R.drawable.tailor));

        // Important Services Cards - First Row
        itemList.add(new Item("জরুরি সেবা", R.drawable.emergency));
        itemList.add(new Item("জরুরী তথ্য", R.drawable.govtinfo));
        itemList.add(new Item("জরুরী নম্বার", R.drawable.emergencycall));

        // Important Services Cards - Second Row
        itemList.add(new Item("থানা পুলিশ", R.drawable.poli));
        itemList.add(new Item("ফায়ার সার্ভিস", R.drawable.fire));
        itemList.add(new Item("সকল সিমের কোড", R.drawable.sokolsim));




        itemList.add(new Item("আইনজীবী তালিকা", R.drawable.lawyer));

  
        // ---- Education ----
        itemList.add(new Item("পাবলিক লাইব্রেরি", R.drawable.library));


        // ---- Women & Family Welfare ----
        itemList.add(new Item("নারী উদ্যোক্তা কেন্দ্র", R.drawable.women_ent));

        itemList.add(new Item("যুব ক্লাব", R.drawable.youth_club));
        itemList.add(new Item("স্বেচ্ছাসেবী সংগঠন", R.drawable.organization));
        itemList.add(new Item("রক্তদান সংগঠন", R.drawable.blood_organization));

        // ---- Sports & Recreation ----
        itemList.add(new Item("স্পোর্টস ক্লাব", R.drawable.sports_club));


        // Set adapter
        adapter = new RecyclerAdapter(getContext(), itemList);
        recyclerView.setAdapter(adapter);

        return view;
    }
}