package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.AppCompatButton;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.helper.AuthRequest;
import com.example.betagiesheva.AddUnifiedGovtItemActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedGovtItem;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class UnifiedGovtItemAdapter extends RecyclerView.Adapter<UnifiedGovtItemAdapter.ViewHolder> {

    private static final String TAG = "UnifiedGovtItemAdapter";
    private List<UnifiedGovtItem> itemList;
    private List<UnifiedGovtItem> itemListFull; // For search functionality
    private Context context;
    private final SessionManager sessionManager;

    public UnifiedGovtItemAdapter(Context context, List<UnifiedGovtItem> itemList) {
        this.context = context;
        this.itemList = new ArrayList<>(itemList);
        this.itemListFull = new ArrayList<>(itemList);
        this.sessionManager = new SessionManager(context);
        Log.d(TAG, "Adapter initialized with " + itemList.size() + " items");
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_unified_govt, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        UnifiedGovtItem item = itemList.get(position);

        // Set name with null check
        if (item.getName() != null && !item.getName().isEmpty()) {
            holder.nameTextView.setText(item.getName());
        } else {
            holder.nameTextView.setText("নাম নেই");
        }

        // Set address with null check
        if (item.getAddress() != null && !item.getAddress().isEmpty()) {
            holder.addressTextView.setText(item.getAddress());
        } else {
            holder.addressTextView.setText("ঠিকানা নেই");
        }

        // Set phone number with Bengali prefix and null check
        if (item.getPhoneNumber() != null && !item.getPhoneNumber().isEmpty()) {
            holder.phoneTextView.setText("যোগাযোগ: " + item.getPhoneNumber());
        } else {
            holder.phoneTextView.setText("যোগাযোগ নেই");
        }

        // Load image - always use drawable for better performance
        holder.imageView.setImageResource(getDefaultImageForType(item.getItemType()));

        // Set click listener for call button
        View.OnClickListener callListener = v -> makePhoneCall(item.getPhoneNumber());
        holder.callAnimation.setOnClickListener(callListener);
        holder.callTextView.setOnClickListener(callListener);

        // Optional: Set click listener for entire item
        holder.itemView.setOnClickListener(v -> {
            if (item.getName() != null && !item.getName().isEmpty()) {
                Toast.makeText(context, item.getName(), Toast.LENGTH_SHORT).show();
            }
        });

        // Show admin buttons (edit/delete) for admin users
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {
            // Edit button
            holder.btnEdit.setOnClickListener(v -> {
                if (position >= 0 && position < itemList.size()) {
                    UnifiedGovtItem selectedItem = itemList.get(position);
                    Intent intent = new Intent(context, AddUnifiedGovtItemActivity.class);
                    intent.putExtra("govt_item_data", selectedItem);
                    intent.putExtra("item_type", selectedItem.getItemType().name());
                    context.startActivity(intent);
                }
            });

            // Delete button
            holder.btnDelete.setOnClickListener(v -> {
                if (position >= 0 && position < itemList.size()) {
                    deleteGovtItem(itemList.get(position).getId(), position);
                }
            });
        }

        Log.d(TAG, "Bound item at position " + position + ": " + item.getName());
    }

    @Override
    public int getItemCount() {
        int count = itemList.size();
        Log.d(TAG, "getItemCount: " + count);
        return count;
    }

    // Method to make phone call
    private void makePhoneCall(String phoneNumber) {
        if (phoneNumber != null && !phoneNumber.isEmpty()) {
            Intent callIntent = new Intent(Intent.ACTION_DIAL);
            callIntent.setData(Uri.parse("tel:" + phoneNumber));
            context.startActivity(callIntent);
        } else {
            Toast.makeText(context, "ফোন নম্বর পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
        }
    }

    // Get default image based on item type
    private int getDefaultImageForType(UnifiedGovtItem.ItemType itemType) {
        if (itemType == null) {
            return R.drawable.coaching; // Default fallback
        }

        switch (itemType) {
            case BANK:
                return R.drawable.bank;
            case COURIER:
                return R.drawable.ic_courier;
            case COACHING_CENTER:
                return R.drawable.coaching;
            default:
                return R.drawable.coaching;
        }
    }

    // Update list method
    public void updateList(List<UnifiedGovtItem> newList) {
        Log.d(TAG, "updateList called with " + (newList != null ? newList.size() : 0) + " items");

        itemList.clear();
        itemListFull.clear();

        if (newList != null) {
            itemList.addAll(newList);
            itemListFull.addAll(newList);
        }

        Log.d(TAG, "After update - itemList: " + itemList.size() +
                ", itemListFull: " + itemListFull.size());

        notifyDataSetChanged();
    }

    // Filter method for local search
    public void filter(String query) {
        Log.d(TAG, "Filtering with query: " + query);

        itemList.clear();

        if (query == null || query.isEmpty()) {
            itemList.addAll(itemListFull);
        } else {
            String lowerCaseQuery = query.toLowerCase().trim();
            for (UnifiedGovtItem item : itemListFull) {
                boolean matchFound = false;

                // Check name
                if (item.getName() != null && item.getName().toLowerCase().contains(lowerCaseQuery)) {
                    matchFound = true;
                }

                // Check address
                if (!matchFound && item.getAddress() != null &&
                        item.getAddress().toLowerCase().contains(lowerCaseQuery)) {
                    matchFound = true;
                }

                // Check phone number
                if (!matchFound && item.getPhoneNumber() != null &&
                        item.getPhoneNumber().contains(lowerCaseQuery)) {
                    matchFound = true;
                }

                if (matchFound) {
                    itemList.add(item);
                }
            }
        }

        Log.d(TAG, "After filter: " + itemList.size() + " items");
        notifyDataSetChanged();
    }

    // Clear all items
    public void clearList() {
        itemList.clear();
        itemListFull.clear();
        notifyDataSetChanged();
        Log.d(TAG, "List cleared");
    }

    // Get current list size
    public int getCurrentListSize() {
        return itemList.size();
    }

    private void deleteGovtItem(int govtItemId, int position) {
        AuthRequest request = new AuthRequest(Request.Method.POST, Config.DELETE_UNIFIED_GOVT_ITEM,
                response -> {
                    Toast.makeText(context, "সংস্থা মুছে দেওয়া হয়েছে", Toast.LENGTH_SHORT).show();
                    if (position >= 0 && position < itemList.size()) {
                        itemList.remove(position);
                        itemListFull.removeIf(item -> item.getId() == govtItemId);
                        notifyItemRemoved(position);
                    }
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "মুছে ফেলা ব্যর্থ হয়েছে", Toast.LENGTH_SHORT).show();
                },
                context) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> params = new HashMap<>();
                params.put("id", String.valueOf(govtItemId));
                return params;
            }
        };

        Config.getInstance(context).addToRequestQueue(request);
    }

    // ViewHolder class
    public static class ViewHolder extends RecyclerView.ViewHolder {
        CircleImageView imageView;
        TextView nameTextView;
        TextView addressTextView;
        TextView phoneTextView;
        LottieAnimationView callAnimation;
        TextView callTextView;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.coaching_image);
            nameTextView = itemView.findViewById(R.id.unified_govt_name);
            addressTextView = itemView.findViewById(R.id.unified_govt_address);
            phoneTextView = itemView.findViewById(R.id.unified_govt_phone);
            callAnimation = itemView.findViewById(R.id.lottie_call_unified_govt);
            callTextView = itemView.findViewById(R.id.text_call_unified_govt);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}