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
import com.bumptech.glide.Glide;
import com.example.betagiesheva.helper.AuthRequest;
import com.example.betagiesheva.AddUnifiedPersonActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedPerson;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

/**
 * Adapter for displaying UnifiedPerson in RecyclerView
 * Supports image loading with Glide, phone call functionality, type-based styling,
 * and admin edit/delete operations
 */
public class UnifiedUserItemAdapter extends RecyclerView.Adapter<UnifiedUserItemAdapter.UserViewHolder> {

    private static final String TAG = "UnifiedUserItemAdapter";

    private Context context;
    private List<UnifiedPerson> userItemList;
    private List<UnifiedPerson> userItemListFull; // For search/filter
    private final SessionManager sessionManager;

    public UnifiedUserItemAdapter(Context context, List<UnifiedPerson> userItemList) {
        this.context = context;
        this.userItemList = new ArrayList<>(userItemList);
        this.userItemListFull = new ArrayList<>(userItemList);
        this.sessionManager = new SessionManager(context);
    }

    @NonNull
    @Override
    public UserViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_unified_user_item, parent, false);
        return new UserViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull UserViewHolder holder, int position) {
        try {
            UnifiedPerson item = userItemList.get(position);

            // Set item name
            holder.ItemName.setText(item.getName() != null && !item.getName().isEmpty()
                    ? item.getName() : "নাম নেই");

            // Set item phone number
            holder.ItemPhone.setText(item.getPhone() != null && !item.getPhone().isEmpty()
                    ? "যোগাযোগ: " + item.getPhone() : "যোগাযোগ নেই");

            // Set item address if available
            if (item.getAddress() != null && !item.getAddress().isEmpty()) {
                holder.ItemAddress.setText(item.getAddress());
                holder.ItemAddress.setVisibility(View.VISIBLE);
            } else {
                holder.ItemAddress.setVisibility(View.GONE);
            }

            // Load item image with Glide
            if (item.getImageUrl() != null && !item.getImageUrl().isEmpty() &&
                    !item.getImageUrl().contains("example.com")) {
                Glide.with(context)
                        .load(item.getImageUrl())
                        .placeholder(getItemTypeImage(item.getPersonType()))
                        .error(getItemTypeImage(item.getPersonType()))
                        .into(holder.ItemImage);
            } else {
                holder.ItemImage.setImageResource(getItemTypeImage(item.getPersonType()));
            }

            // Call button click listener
            View.OnClickListener callListener = v -> {
                if (item.getPhone() != null && !item.getPhone().isEmpty()) {
                    Intent intent = new Intent(Intent.ACTION_DIAL);
                    intent.setData(Uri.parse("tel:" + item.getPhone()));
                    context.startActivity(intent);
                    Log.d(TAG, "Calling: " + item.getName() + " at " + item.getPhone());
                } else {
                    Toast.makeText(context, "ফোন নম্বর পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
                    Log.w(TAG, "Item has no phone number: " + item.getName());
                }
            };
            holder.lottieCall.setOnClickListener(callListener);
            holder.textCall.setOnClickListener(callListener);

            // Show admin buttons
            boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
            holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

            if (isAdmin) {
                // Edit button
                holder.btnEdit.setOnClickListener(v -> {
                    if (position >= 0 && position < userItemList.size()) {
                        UnifiedPerson selectedPerson = userItemList.get(position);
                        Intent intent = new Intent(context, AddUnifiedPersonActivity.class);
                        intent.putExtra("person_data", selectedPerson);
                        intent.putExtra("personType", selectedPerson.getPersonType());
                        context.startActivity(intent);
                    }
                });

                // Delete button
                holder.btnDelete.setOnClickListener(v -> {
                    if (position >= 0 && position < userItemList.size()) {
                        deleteUnifiedPerson(userItemList.get(position).getId(), position);
                    }
                });
            }

            Log.d(TAG, "Bound item at position " + position + ": " + item.getName());

        } catch (Exception e) {
            Log.e(TAG, "Error binding view holder at position " + position, e);
        }
    }

    @Override
    public int getItemCount() {
        return userItemList.size();
    }

    private void deleteUnifiedPerson(String personId, int position) {
        AuthRequest request = new AuthRequest(Request.Method.POST, Config.DELETE_UNIFIED_PERSON,
                response -> {
                    Toast.makeText(context, "ব্যক্তি মুছে দেওয়া হয়েছে", Toast.LENGTH_SHORT).show();
                    if (position >= 0 && position < userItemList.size()) {
                        userItemList.remove(position);
                        userItemListFull.removeIf(item -> item.getId().equals(personId));
                        notifyItemRemoved(position);
                        Log.d(TAG, "Deleted person at position " + position);
                    }
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "মুছতে ব্যর্থ হয়েছে", Toast.LENGTH_SHORT).show();
                    Log.e(TAG, "Delete error: " + error.getMessage());
                },
                context) {
            @Override
            protected Map<String, String> getParams() {
                Map<String, String> params = new HashMap<>();
                params.put("id", personId);
                return params;
            }
        };

        Config.getInstance(context).addToRequestQueue(request);
    }

    /**
     * Get display name for item type in Bengali
     */
    private String getTypeDisplayName(String itemType) {
        if (itemType == null || itemType.isEmpty()) {
            return "সাধারণ";
        }

        switch (itemType) {
            case UnifiedPerson.TYPE_GHATOK:
                return "ঘটক";
            case UnifiedPerson.TYPE_JOURNALIST:
                return "সাংবাদিক";
            case UnifiedPerson.TYPE_COACHING_CENTER:
                return "কোচিং সেন্টার";
            case UnifiedPerson.TYPE_DEED_WRITER:
                return "দলিল লেখক";
            case UnifiedPerson.TYPE_SURVEYOR:
                return "সার্ভেয়ার";
            default:
                return itemType;
        }
    }

    /**
     * Get default image resource based on item type
     */
    private int getItemTypeImage(String itemType) {
        if (itemType == null || itemType.isEmpty()) {
            return R.drawable.alldepartment;
        }

        switch (itemType) {
            case UnifiedPerson.TYPE_GHATOK:
                return R.drawable.alldepartment;
            case UnifiedPerson.TYPE_JOURNALIST:
                return R.drawable.alldepartment;
            case UnifiedPerson.TYPE_COACHING_CENTER:
                return R.drawable.coaching;
            case UnifiedPerson.TYPE_DEED_WRITER:
                return R.drawable.poli;
            case UnifiedPerson.TYPE_SURVEYOR:
                return R.drawable.gas;
            default:
                return R.drawable.alldepartment;
        }
    }

    /**
     * Filter by search query
     */
    public void filter(String query) {
        userItemList.clear();
        if (query == null || query.isEmpty()) {
            userItemList.addAll(userItemListFull);
        } else {
            String q = query.toLowerCase().trim();
            for (UnifiedPerson item : userItemListFull) {
                if ((item.getName() != null && item.getName().toLowerCase().contains(q)) ||
                        (item.getPersonType() != null && item.getPersonType().toLowerCase().contains(q)) ||
                        (item.getPhone() != null && item.getPhone().contains(q)) ||
                        (item.getAddress() != null && item.getAddress().toLowerCase().contains(q)) ||
                        (item.getUnion() != null && item.getUnion().toLowerCase().contains(q))) {
                    userItemList.add(item);
                }
            }
        }
        notifyDataSetChanged();
        Log.d(TAG, "Filter applied for query: '" + query + "' - Found " + userItemList.size() + " items");
    }

    /**
     * Update adapter list with new data
     */
    public void updateList(List<UnifiedPerson> newList) {
        userItemList.clear();
        userItemListFull.clear();
        if (newList != null) {
            userItemList.addAll(newList);
            userItemListFull.addAll(newList);
        }
        notifyDataSetChanged();
        Log.d(TAG, "List updated with " + userItemList.size() + " items");
    }

    /**
     * Add items for pagination
     */
    public void addItems(List<UnifiedPerson> newItems) {
        if (newItems != null && !newItems.isEmpty()) {
            int startPosition = userItemList.size();
            userItemList.addAll(newItems);
            userItemListFull.addAll(newItems);
            notifyItemRangeInserted(startPosition, newItems.size());
            Log.d(TAG, "Added " + newItems.size() + " items for pagination");
        }
    }

    /**
     * Clear all items
     */
    public void clear() {
        userItemList.clear();
        userItemListFull.clear();
        notifyDataSetChanged();
        Log.d(TAG, "Adapter cleared");
    }

    /**
     * ViewHolder for UnifiedPerson
     */
    public static class UserViewHolder extends RecyclerView.ViewHolder {
        CircleImageView ItemImage;
        TextView ItemName, ItemPhone, ItemAddress, textCall;
        LottieAnimationView lottieCall;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public UserViewHolder(@NonNull View itemView) {
            super(itemView);
            ItemImage = itemView.findViewById(R.id.item_image);
            ItemName = itemView.findViewById(R.id.item_name);
            ItemPhone = itemView.findViewById(R.id.item_phone);
            ItemAddress = itemView.findViewById(R.id.item_address);
            lottieCall = itemView.findViewById(R.id.lottie_call_user);
            textCall = itemView.findViewById(R.id.text_call_user);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}