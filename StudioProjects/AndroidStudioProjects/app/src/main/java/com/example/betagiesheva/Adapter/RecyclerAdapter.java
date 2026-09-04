package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.betagiesheva.BloodDonationActivity;
import com.example.betagiesheva.Blood_Donation_Activity;
import com.example.betagiesheva.BusActivity;
import com.example.betagiesheva.ClinicActivity;
import com.example.betagiesheva.CoupsActivity;
import com.example.betagiesheva.EduActivity;
import com.example.betagiesheva.EmergencyNumbersActivity;
import com.example.betagiesheva.FreedomActivity;
import com.example.betagiesheva.HospitalActivity;
import com.example.betagiesheva.JulyActivity;
import com.example.betagiesheva.Model.Item;

import com.example.betagiesheva.Model.UnifiedGovtOfficer;

import com.example.betagiesheva.Model.UnifiedPerson;
import com.example.betagiesheva.NewspaperActivity;
import com.example.betagiesheva.PostActivity;
import com.example.betagiesheva.R;
import com.example.betagiesheva.ShopActivity;
import com.example.betagiesheva.SimActivity;
import com.example.betagiesheva.SpecialistsActivity;
import com.example.betagiesheva.TouristActivity;
import com.example.betagiesheva.TuitionActivity;
import com.example.betagiesheva.UnifiedBusinessItemActivity;
import com.example.betagiesheva.UnifiedGovtItemActivity;
import com.example.betagiesheva.UnifiedGovtOfficerActivity;
import com.example.betagiesheva.UnifiedUserItemActivity;
import com.example.betagiesheva.UpazilaInfoActivity;


import java.util.List;

public class RecyclerAdapter extends RecyclerView.Adapter<RecyclerAdapter.ViewHolder> {
    private Context context;
    private List<Item> itemList;

    public RecyclerAdapter(Context context, List<Item> itemList) {
        this.context = context;
        this.itemList = itemList;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.grid_item, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Item item = itemList.get(position);
        holder.itemTitle.setText(item.getTitle());
        holder.itemImage.setImageResource(item.getImageResId());

        holder.itemView.setOnClickListener(v -> {
            String title = item.getTitle();

            // Check if this item matches any officer type
            String officerType = getOfficerTypeFromTitle(title);
            if (officerType != null) {
                openUnifiedGovtOfficerActivity(officerType);
                return;
            }

            // Check if this item matches any user type
            String userType = getUserTypeFromTitle(title);
            if (userType != null) {
                openUnifiedUserItemActivity(userType, title);
                return;
            }

            // Handle other items by title
            switch (title) {
                // Health Services
                case "হাসপাতাল":
                    context.startActivity(new Intent(context, HospitalActivity.class));
                    break;
                case "ক্লিনিক":
                    context.startActivity(new Intent(context, ClinicActivity.class));
                    break;
                case "ডাক্তার":
                    context.startActivity(new Intent(context, SpecialistsActivity.class));
                    break;
                case "ফার্মেসি":
                    openUnifiedBusinessActivity("pharmacy", "ফার্মেসী");
                    break;
                case "অ্যাম্বুলেন্স":
                    openUnifiedBusinessActivity("ambulance", "অ্যাম্বুলেন্স সার্ভিস");
                    break;
                case "ব্লাড ডোনার":
                    context.startActivity(new Intent(context, BloodDonationActivity.class));
                    break;

                // All Services
                case "দর্শনীয় স্থান":
                    context.startActivity(new Intent(context, TouristActivity.class));
                    break;
                case "হোটেল":
                    openUnifiedBusinessActivity("hotels", "হোটেল");
                    break;
                case "পত্রিকা":
                    context.startActivity(new Intent(context, NewspaperActivity.class));
                    break;
                case "উপজেলা তথ্য":
                    context.startActivity(new Intent(context, UpazilaInfoActivity.class));
                    break;
                case "নার্সারি দোকান":
                    openUnifiedBusinessActivity("nursery", "নার্সারি দোকান");
                    break;
                case "কুরিয়ার সার্ভিস":
                    openUnifiedGovtItemActivity("কুরিয়ার", "কুরিয়ার সার্ভিস");
                    break;
                case "পোষ্ট অফিস":
                    context.startActivity(new Intent(context, PostActivity.class));
                    break;
                case "শিক্ষা প্রতিষ্ঠান":
                    context.startActivity(new Intent(context, EduActivity.class));
                    break;
                case "ব্যাংক":
                    openUnifiedGovtItemActivity("ব্যাংক", "ব্যাংক");
                    break;
                case "রেস্টুরেন্ট":
                    openUnifiedBusinessActivity("restaurant", "রেস্টুরেন্ট");
                    break;
                case "বিউটি পার্লার":
                    openUnifiedBusinessActivity("beauty_parlor", "বিউটি পার্লার");
                    break;
                case "প্রশিক্ষণ কেন্দ্র":
                    openUnifiedBusinessActivity("training_center", "প্রশিক্ষণ কেন্দ্র");
                    break;

                case "দোকান-শোরুম":
                    context.startActivity(new Intent(context, ShopActivity.class));
                    break;
                case "বাস":
                    context.startActivity(new Intent(context, BusActivity.class));
                    break;
                case "অনলাইন সার্ভিস":
                    openUnifiedBusinessActivity("online_services", "অনলাইন সার্ভিস");
                    break;
                case "টিউশন সার্ভিস":
                    context.startActivity(new Intent(context, TuitionActivity.class));
                    break;

                // History
                case "জুলাই বিপ্লব":
                    context.startActivity(new Intent(context, JulyActivity.class));
                    break;
                case "সকল সামরিক অভ্যুত্থান":
                    context.startActivity(new Intent(context, CoupsActivity.class));
                    break;
                case "মহান মুক্তিযুদ্ধ":
                    context.startActivity(new Intent(context, FreedomActivity.class));
                    break;

                // Mistri Services
                case "কাঠের মিস্ত্রি":
                    openUnifiedBusinessActivity("carpenter", "কাঠের মিস্ত্রি");
                    break;
                case "রাজমিস্ত্রি":
                    openUnifiedBusinessActivity("building_contractor", "রাজমিস্ত্রি");
                    break;
                case "রং মিস্ত্রি":
                    openUnifiedBusinessActivity("painter", "রং মিস্ত্রি");
                    break;
                case "গাড়ি মেকার":
                    openUnifiedBusinessActivity("car_mechanic", "গাড়ি মেকার");
                    break;
                case "ইলেক্ট্রনিকাল মেকার":
                    openUnifiedBusinessActivity("electrician", "ইলেক্ট্রনিকাল মেকার");
                    break;
                case "দর্জি কারিগর":
                    openUnifiedBusinessActivity("tailor", "দর্জি কারিগর");
                    break;

                // Important Services
                case "জরুরি সেবা":
                    context.startActivity(new Intent(context, EmergencyNumbersActivity.class));
                    break;
                case "জরুরী তথ্য":
                    context.startActivity(new Intent(context, UpazilaInfoActivity.class));
                    break;
                case "জরুরী নম্বার":
                    dialEmergencyNumber("999");
                    break;
                case "সকল সিমের কোড":
                    context.startActivity(new Intent(context, SimActivity.class));
                    break;

                // Newly added items -> routed through UnifiedGovtItemActivity
                // (same pattern as কুরিয়ার সার্ভিস / ব্যাংক: simple institution/place listing,
                // no proprietor field needed, matches unified_govt_items table)
                case "পল্লি বিদ্যুৎ":
                    openUnifiedGovtItemActivity("পল্লি বিদ্যুৎ", "পল্লি বিদ্যুৎ");
                    break;
                case "পাবলিক লাইব্রেরি":
                    openUnifiedGovtItemActivity("পাবলিক লাইব্রেরি", "পাবলিক লাইব্রেরি");
                    break;
                case "নারী উদ্যোক্তা কেন্দ্র":
                    openUnifiedGovtItemActivity("নারী উদ্যোক্তা কেন্দ্র", "নারী উদ্যোক্তা কেন্দ্র");
                    break;
                case "যুব ক্লাব":
                    openUnifiedGovtItemActivity("যুব ক্লাব", "যুব ক্লাব");
                    break;
                case "স্বেচ্ছাসেবী সংগঠন":
                    openUnifiedGovtItemActivity("স্বেচ্ছাসেবী সংগঠন", "স্বেচ্ছাসেবী সংগঠন");
                    break;
                case "রক্তদান সংগঠন":
                    openUnifiedGovtItemActivity("রক্তদান সংগঠন", "রক্তদান সংগঠন");
                    break;
                case "স্পোর্টস ক্লাব":
                    openUnifiedGovtItemActivity("স্পোর্টস ক্লাব", "স্পোর্টস ক্লাব");
                    break;

                default:
                    // Do nothing for unhandled items
                    break;
            }
        });
    }

    @Override
    public int getItemCount() {
        return itemList.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView itemTitle;
        ImageView itemImage;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            itemTitle = itemView.findViewById(R.id.item_title);
            itemImage = itemView.findViewById(R.id.item_image);
        }
    }

    private String getOfficerTypeFromTitle(String title) {
        switch (title) {
            case "উপজেলা ডাক্তার":
                return UnifiedGovtOfficer.TYPE_UPAZILA_DOCTOR;
            case "পশু ডাক্তার":
                return UnifiedGovtOfficer.TYPE_VETERINARY_DOCTOR;
            case "নার্স সেবা":
                return UnifiedGovtOfficer.TYPE_NURSE;
            case "থানা পুলিশ":
                return UnifiedGovtOfficer.TYPE_POLICE;
            case "ফায়ার সার্ভিস":
                return UnifiedGovtOfficer.TYPE_FIRE_SERVICE;
            default:
                return null;
        }
    }

    private String getUserTypeFromTitle(String title) {
        switch (title) {
            case "বিয়ের ঘটক":
                return UnifiedPerson.TYPE_GHATOK;
            case "সাংবাদিক":
                return UnifiedPerson.TYPE_JOURNALIST;
            case "কোচিং সেন্টার":
                return UnifiedPerson.TYPE_COACHING_CENTER;
            case "দলিল লেখক":
                return UnifiedPerson.TYPE_DEED_WRITER;
            case "সার্ভেয়ার":
                return UnifiedPerson.TYPE_SURVEYOR;
            case "আইনজীবী তালিকা":
                return "lawyer"; // TODO: add UnifiedPerson.TYPE_LAWYER constant in Model/UnifiedPerson.java for consistency
            default:
                return null;
        }
    }

    private void openUnifiedGovtOfficerActivity(String officerType) {
        Intent intent = new Intent(context, UnifiedGovtOfficerActivity.class);
        intent.putExtra("officerType", officerType);
        context.startActivity(intent);
    }

    private void openUnifiedUserItemActivity(String userType, String displayName) {
        Intent intent = new Intent(context, UnifiedUserItemActivity.class);
        intent.putExtra("userType", userType);
        intent.putExtra("displayName", displayName);
        context.startActivity(intent);
    }

    private void openUnifiedBusinessActivity(String businessType, String displayName) {
        Intent intent = new Intent(context, UnifiedBusinessItemActivity.class);
        intent.putExtra("businessType", businessType);
        intent.putExtra("displayName", displayName);
        String category = getBusinessCategory(businessType);
        intent.putExtra("category", category);
        context.startActivity(intent);
    }

    private void openUnifiedGovtItemActivity(String govtType, String displayName) {
        Intent intent = new Intent(context, UnifiedGovtItemActivity.class);
        intent.putExtra("govtType", govtType);
        intent.putExtra("displayName", displayName);
        // For govt items, we might also need a category mapping if needed
        // For now, using govtType as both identifier and category
        context.startActivity(intent);
    }

    private void dialEmergencyNumber(String number) {
        Intent intent = new Intent(Intent.ACTION_DIAL);
        intent.setData(Uri.parse("tel:" + number));
        context.startActivity(intent);
    }

    /**
     * Maps businessType (internal key) to category name (database value)
     * This ensures data is fetched from the correct category in the database
     */
    private String getBusinessCategory(String businessType) {
        switch (businessType) {
            case "pharmacy":
                return "ফার্মেসি";
            case "ambulance":
                return "অ্যাম্বুলেন্স";

            case "hotels":
                return "হোটেল";
            case "newspapers":
                return "সংবাদপত্র";
            case "nursery":
                return "নার্সারি দোকান";
            case "restaurant":
                return "রেস্টুরেন্ট";
            case "beauty_parlor":
                return "বিউটি পার্লার";
            case "training_center":
                return "প্রশিক্ষণ কেন্দ্র";
            case "jobs":
                return "চাকুরির বিজ্ঞপ্তি";
            case "car_rentals":
                return "গাড়ি ভাড়া";
            case "online_services":
                return "অনলাইন সার্ভিস";
            case "tuition_services":
                return "টিউশন সার্ভিস";
            case "carpenter":
                return "কাঠমিস্ত্রী";
            case "electrician":
                return "ইলেক্ট্রনিকাল মেকার";
            case "painter":
                return "রং মিস্ত্রী";
            case "tailor":
                return "ট্রেইলর";
            case "plumber":
                return "প্লাম্বার";
            case "mechanic":
                return "গাড়ি মেকার";
            case "grocery":
                return "গ্রোসারি শপ";
            case "electronics":
                return "ইলেকট্রনিক্স শপ";
            case "jewelry":
                return "জুয়েলার্স শপ";
            case "furniture":
                return "ফার্নিচার শপ";
            case "clothing":
                return "কাপরের দোকান";
            case "concrete":
                return "কংক্রিট শপ";
            case "decoration":
                return "ডেকারোটার্স শপ";
            default:
                // Return the displayName or businessType as fallback
                return businessType;
        }
    }
}