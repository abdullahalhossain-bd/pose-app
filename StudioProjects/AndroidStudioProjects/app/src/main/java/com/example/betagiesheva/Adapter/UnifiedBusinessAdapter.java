package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.example.betagiesheva.AddUnifiedBusinessItemActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedBusinessItem;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.helper.AuthRequest;

import java.util.ArrayList;
import java.util.List;

public class UnifiedBusinessAdapter extends RecyclerView.Adapter<UnifiedBusinessAdapter.ViewHolder> {

    private final Context context;
    private final List<UnifiedBusinessItem> businessItemList;
    private final SessionManager sessionManager;

    public UnifiedBusinessAdapter(Context context, List<UnifiedBusinessItem> list) {
        this.context = context;
        this.businessItemList = list != null ? list : new ArrayList<>();
        this.sessionManager = new SessionManager(context);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context)
                .inflate(R.layout.item_unified_business_item, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        if (position >= businessItemList.size()) return;

        UnifiedBusinessItem item = businessItemList.get(position);
        if (item == null) return;

        // Name
        holder.nameTextView.setText(item.getName() != null && !item.getName().isEmpty() ? item.getName() : "N/A");

        // Proprietor Name
        holder.proprietorNameTextView.setText(
                item.getProprietorName() != null && !item.getProprietorName().isEmpty()
                        ? "প্রোপ্রাইটর: " + item.getProprietorName()
                        : "প্রোপ্রাইটর পাওয়া যায়নি"
        );

        // Address
        holder.addressTextView.setText(
                item.getAddress() != null && !item.getAddress().trim().isEmpty()
                        ? item.getAddress()
                        : "ঠিকানা পাওয়া যায়নি"
        );

        // Details
        if (item.getDetails() != null && !item.getDetails().isEmpty()) {
            holder.detailsTextView.setText(item.getDetails());
            holder.detailsTextView.setVisibility(View.VISIBLE);
        } else {
            holder.detailsTextView.setVisibility(View.GONE);
        }

        // Load Image from URL using Glide
        String imageUrl = item.getImage();
        if (imageUrl != null && !imageUrl.isEmpty()) {
            Glide.with(context)
                    .load(imageUrl)
                    .placeholder(getDefaultImageForBusinessType(item.getBusinessType()))
                    .error(R.drawable.allshop)
                    .diskCacheStrategy(DiskCacheStrategy.ALL)
                    .into(holder.imageView);
        } else {
            holder.imageView.setImageResource(getDefaultImageForBusinessType(item.getBusinessType()));
        }

        // Call button
        holder.callButton.setOnClickListener(v -> {
            if (item.getPhone() != null && !item.getPhone().isEmpty()) {
                Intent intent = new Intent(Intent.ACTION_DIAL);
                intent.setData(Uri.parse("tel:" + item.getPhone()));
                context.startActivity(intent);
            } else {
                Toast.makeText(context, "ফোন নম্বর পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
            }
        });

        // Admin actions
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {
            holder.btnEdit.setOnClickListener(v -> {
                if (position >= 0 && position < businessItemList.size()) {
                    UnifiedBusinessItem selectedItem = businessItemList.get(position);
                    Intent intent = new Intent(context, AddUnifiedBusinessItemActivity.class);
                    intent.putExtra("business_data", selectedItem);
                    context.startActivity(intent);
                }
            });

            holder.btnDelete.setOnClickListener(v -> {
                if (position >= 0 && position < businessItemList.size()) {
                    deleteBusinessItem(businessItemList.get(position).getId(), position);
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        return businessItemList.size();
    }

    private int getDefaultImageForBusinessType(String businessType) {
        if (businessType == null) return R.drawable.allshop;

        switch (businessType.trim()) {
            case "ফার্মেসি": case "pharmacy": return R.drawable.pharmacy;
            case "অ্যাম্বুলেন্স": case "ambulance": return R.drawable.emergency;
            case "নার্সারি দোকান": case "nursery": return R.drawable.nursey_dokan;
            case "রেস্টুরেন্ট": case "restaurant": return R.drawable.resturent;
            case "বিউটি পার্লার": case "beauty_parlor": return R.drawable.parlour;
            case "ট্রেইলর": case "tailor": return R.drawable.tailor;
            case "কাঠমিস্ত্রী": case "carpenter": return R.drawable.carpenter;
            case "ইলেক্ট্রনিকাল মেকার": case "electrician": return R.drawable.electrician;
            case "গাড়ি মেকার": case "car_mechanic": return R.drawable.car;
            case "রং মিস্ত্রি": case "painter": return R.drawable.ic_painter;
            case "রাজমিস্ত্রি": case "building_contractor": return R.drawable.brilding;
            case "গ্রোসারি শপ": case "grocery": return R.drawable.groshop;
            case "ইলেকট্রনিক্স শপ": case "electronics": return R.drawable.electro;
            case "জুয়েলার্স শপ": case "jewelry": return R.drawable.jewelershop;
            case "ফার্নিচার শপ": case "furniture": return R.drawable.furnitureshop;
            case "কাপরের দোকান": case "clothing": return R.drawable.cloth;
            case "প্রশিক্ষণ কেন্দ্র": case "training_center": return R.drawable.ic_traning;
            case "টিউশন সার্ভিস": case "tuition_services": return R.drawable.coaching;
            case "অনলাইন সার্ভিস": case "online_services": return R.drawable.onlineservice;
            default: return R.drawable.allshop;
        }
    }

    public void setList(List<UnifiedBusinessItem> newItems) {
        businessItemList.clear();
        if (newItems != null) businessItemList.addAll(newItems);
        notifyDataSetChanged();
    }

    private void deleteBusinessItem(String itemId, int position) {
        // delete_unified_business.php only accepts POST (it returns
        // "Method not allowed" / 405 for GET) — the id is still read from
        // the query string as a fallback, so we keep it on the URL and just
        // switch the HTTP method.
        String url = Config.BASE_URL + "delete_unified_business.php?id=" + itemId;

        AuthRequest request = new AuthRequest(Request.Method.POST, url,
                response -> {
                    Toast.makeText(context, "ব্যবসা মুছে ফেলা হয়েছে", Toast.LENGTH_SHORT).show();
                    if (position >= 0 && position < businessItemList.size()) {
                        businessItemList.remove(position);
                        notifyItemRemoved(position);
                    }
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "মুছে ফেলতে ব্যর্থ", Toast.LENGTH_SHORT).show();
                },
                context);

        Config.getInstance(context).addToRequestQueue(request);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView imageView;
        TextView nameTextView, proprietorNameTextView, addressTextView, detailsTextView;
        Button callButton;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.unified_business_item_image);
            nameTextView = itemView.findViewById(R.id.Unified_business_item_name);
            proprietorNameTextView = itemView.findViewById(R.id.unified_business_item_proprietor_name);
            addressTextView = itemView.findViewById(R.id.unified_business_item_address);
            detailsTextView = itemView.findViewById(R.id.unified_business_item_details);
            callButton = itemView.findViewById(R.id.call_button);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}