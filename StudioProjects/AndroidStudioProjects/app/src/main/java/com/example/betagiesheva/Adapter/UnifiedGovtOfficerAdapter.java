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
import com.example.betagiesheva.AddUnifiedGovtOfficerActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.UnifiedGovtOfficer;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;


import java.util.ArrayList;
import java.util.List;

import de.hdodenhof.circleimageview.CircleImageView;

public class UnifiedGovtOfficerAdapter extends RecyclerView.Adapter<UnifiedGovtOfficerAdapter.OfficerViewHolder> {

    private static final String TAG = "UnifiedGovtOfficerAdapter";
    private Context context;
    private List<UnifiedGovtOfficer> officerList;
    private List<UnifiedGovtOfficer> officerListFull; // For search/filter
    private final SessionManager sessionManager;

    public UnifiedGovtOfficerAdapter(Context context, List<UnifiedGovtOfficer> officerList) {
        this.context = context;
        this.officerList = new ArrayList<>(officerList);
        this.officerListFull = new ArrayList<>(officerList);
        this.sessionManager = new SessionManager(context);
        Log.d(TAG, "Adapter initialized with " + officerList.size() + " officers");
    }

    @NonNull
    @Override
    public OfficerViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_unified_govt_officer, parent, false);
        return new OfficerViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull OfficerViewHolder holder, int position) {
        UnifiedGovtOfficer officer = officerList.get(position);

        // Set officer name
        holder.officerName.setText(officer.getOfficerName() != null && !officer.getOfficerName().isEmpty()
                ? officer.getOfficerName() : "নাম নেই");

        // Set officer rank
        holder.officerRank.setText(officer.getRank() != null && !officer.getRank().isEmpty()
                ? officer.getRank() : "পদবী নেই");

        // Set officer phone number
        holder.officerPhone.setText(officer.getMobileNumber() != null && !officer.getMobileNumber().isEmpty()
                ? "যোগাযোগ: " + officer.getMobileNumber() : "যোগাযোগ নেই");

        // Load officer image with Glide
        if (officer.getImage() != null && !officer.getImage().isEmpty() &&
                !officer.getImage().contains("example.com")) {
            Glide.with(context)
                    .load(officer.getImage())
                    .placeholder(getOfficerTypeImage(officer.getOfficerType()))
                    .error(getOfficerTypeImage(officer.getOfficerType()))
                    .into(holder.officerImage);
        } else {
            holder.officerImage.setImageResource(getOfficerTypeImage(officer.getOfficerType()));
        }

        // Call button
        View.OnClickListener callListener = v -> {
            if (officer.getMobileNumber() != null && !officer.getMobileNumber().isEmpty()) {
                Intent intent = new Intent(Intent.ACTION_DIAL);
                intent.setData(Uri.parse("tel:" + officer.getMobileNumber()));
                context.startActivity(intent);
            } else {
                Toast.makeText(context, "ফোন নম্বর পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
            }
        };
        holder.lottieCall.setOnClickListener(callListener);
        holder.textCall.setOnClickListener(callListener);

        // Show admin buttons (edit/delete) for admin users
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {
            // Edit button
            holder.btnEdit.setOnClickListener(v -> {
                if (position >= 0 && position < officerList.size()) {
                    UnifiedGovtOfficer selectedOfficer = officerList.get(position);
                    Intent intent = new Intent(context, AddUnifiedGovtOfficerActivity.class);
                    intent.putExtra("govt_officer_data", selectedOfficer);
                    intent.putExtra("officer_type", selectedOfficer.getOfficerType());
                    context.startActivity(intent);
                }
            });

            // Delete button
            holder.btnDelete.setOnClickListener(v -> {
                if (position >= 0 && position < officerList.size()) {
                    deleteGovtOfficer(officerList.get(position).getId(), position);
                }
            });
        }

        Log.d(TAG, "Bound officer at position " + position + ": " + officer.getOfficerName());
    }

    @Override
    public int getItemCount() {
        return officerList.size();
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

    // Officer type image
    private int getOfficerTypeImage(String officerType) {
        if (officerType == null || officerType.isEmpty()) {
            return R.drawable.alldepartment;
        }

        switch (officerType) {
            case UnifiedGovtOfficer.TYPE_POLICE:
                return R.drawable.poli;
            case UnifiedGovtOfficer.TYPE_NURSE:
                return R.drawable.nurse;
            case UnifiedGovtOfficer.TYPE_UPAZILA_DOCTOR:
                return R.drawable.doctor;
            case UnifiedGovtOfficer.TYPE_FIRE_SERVICE:
                return R.drawable.fire;
            case UnifiedGovtOfficer.TYPE_VETERINARY_DOCTOR:
                return R.drawable.veterinarian;
            default:
                return R.drawable.alldepartment;
        }
    }

    // Update list
    public void updateList(List<UnifiedGovtOfficer> newList) {
        officerList.clear();
        officerListFull.clear();
        if (newList != null) {
            officerList.addAll(newList);
            officerListFull.addAll(newList);
        }
        notifyDataSetChanged();
        Log.d(TAG, "List updated with " + officerList.size() + " officers");
    }

    // Filter by search
    public void filter(String query) {
        officerList.clear();
        if (query == null || query.isEmpty()) {
            officerList.addAll(officerListFull);
        } else {
            String q = query.toLowerCase().trim();
            for (UnifiedGovtOfficer officer : officerListFull) {
                boolean matchFound = false;

                if (officer.getOfficerName() != null && officer.getOfficerName().toLowerCase().contains(q)) {
                    matchFound = true;
                }

                if (!matchFound && officer.getRank() != null && officer.getRank().toLowerCase().contains(q)) {
                    matchFound = true;
                }

                if (!matchFound && officer.getOfficerType() != null && officer.getOfficerType().toLowerCase().contains(q)) {
                    matchFound = true;
                }

                if (!matchFound && officer.getMobileNumber() != null && officer.getMobileNumber().contains(q)) {
                    matchFound = true;
                }

                if (matchFound) {
                    officerList.add(officer);
                }
            }
        }
        notifyDataSetChanged();
        Log.d(TAG, "Filter applied: " + officerList.size() + " officers match");
    }

    // Clear all items
    public void clearList() {
        officerList.clear();
        officerListFull.clear();
        notifyDataSetChanged();
        Log.d(TAG, "Officer list cleared");
    }

    // Delete officer from API
    private void deleteGovtOfficer(String officerId, int position) {
        String url = Config.BASE_URL + "delete_unified_govt_officer.php?id=" + officerId;

        AuthRequest request = new AuthRequest(Request.Method.GET, url,
                response -> {
                    Toast.makeText(context, "অফিসার মুছে দেওয়া হয়েছে", Toast.LENGTH_SHORT).show();
                    officerList.remove(position);
                    officerListFull.remove(position);
                    notifyItemRemoved(position);
                    Log.d(TAG, "Officer deleted at position " + position);
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "মুছে ফেলা ব্যর্থ হয়েছে", Toast.LENGTH_SHORT).show();
                    Log.e(TAG, "Delete failed: " + error.getMessage());
                },
                context);

        Config.getInstance(context).addToRequestQueue(request);
    }

    // ViewHolder
    public static class OfficerViewHolder extends RecyclerView.ViewHolder {
        CircleImageView officerImage;
        TextView officerName, officerRank, officerPhone, textCall;
        LottieAnimationView lottieCall;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public OfficerViewHolder(@NonNull View itemView) {
            super(itemView);
            officerImage = itemView.findViewById(R.id.unified_govt_officer_image);
            officerName = itemView.findViewById(R.id.unified_govt_officer_name);
            officerRank = itemView.findViewById(R.id.unified_govt_officer_rank);
            officerPhone = itemView.findViewById(R.id.unified_govt_officer_phone);
            lottieCall = itemView.findViewById(R.id.lottie_call);
            textCall = itemView.findViewById(R.id.text_call);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }}
