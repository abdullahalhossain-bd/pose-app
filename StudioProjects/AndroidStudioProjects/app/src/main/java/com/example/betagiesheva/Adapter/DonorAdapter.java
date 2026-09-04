package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.widget.AppCompatButton;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.android.volley.Request;
import com.android.volley.toolbox.StringRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.AddBloodDonationActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.Donor;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.example.betagiesheva.helper.AuthRequest;

import java.util.ArrayList;
import java.util.List;

import de.hdodenhof.circleimageview.CircleImageView;

public class DonorAdapter extends RecyclerView.Adapter<DonorAdapter.DonorViewHolder> {

    private final Context context;
    private final List<Donor> donorList;
    private final List<Donor> donorListFull;
    private final SessionManager sessionManager;

    public DonorAdapter(Context context, List<Donor> donorList) {
        this.context = context;
        this.donorList = donorList;
        this.donorListFull = new ArrayList<>(donorList);
        this.sessionManager = new SessionManager(context);
        
        android.util.Log.d("DonorAdapter", "Adapter initialized with " + donorList.size() + " donors");
    }

    @NonNull
    @Override
    public DonorViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_donor, parent, false);
        return new DonorViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull DonorViewHolder holder, int position) {
        Donor donor = donorList.get(position);
        android.util.Log.d("DonorAdapter", "onBindViewHolder called for position: " + position + ", Donor: " + donor.getName());

        // Text data
        holder.donorName.setText(donor.getName());
        holder.donorAddress.setText(donor.getAddress());
        holder.bloodGroup.setText(donor.getBloodGroup());
        holder.donorPhone.setText(donor.getPhone());

        // ✅ Image loading (FULL URL from API — NO concatenation)
        if (donor.getImage() != null && !donor.getImage().isEmpty()) {
            Glide.with(context)
                    .load(donor.getImage())
                    .placeholder(R.drawable.blood_donar)
                    .error(R.drawable.blood_donar)
                    .into(holder.donorImage);
        } else {
            holder.donorImage.setImageResource(R.drawable.blood_donar);
        }

        // Call actions
        holder.lottieCall.setOnClickListener(v -> makePhoneCall(donor.getPhone()));
        holder.textCall.setOnClickListener(v -> makePhoneCall(donor.getPhone()));

        // Admin controls
        boolean isAdmin = "Admin".equalsIgnoreCase(sessionManager.getUserType());
        holder.bottomRow.setVisibility(isAdmin ? View.VISIBLE : View.GONE);

        if (isAdmin) {

            // Edit donor
            holder.btnEdit.setOnClickListener(v -> {
                Intent intent = new Intent(context, AddBloodDonationActivity.class);
                intent.putExtra("donor_data", donor);
                context.startActivity(intent);
            });

            // Delete donor
            holder.btnDelete.setOnClickListener(v ->
                    deleteDonor(donor.getId(), holder.getAdapterPosition())
            );
        }
    }

    @Override
    public int getItemCount() {
        android.util.Log.d("DonorAdapter", "getItemCount called - returning: " + donorList.size());
        return donorList.size();
    }

    // 📞 Make phone call
    private void makePhoneCall(String phoneNumber) {
        if (phoneNumber != null && !phoneNumber.isEmpty()) {
            Intent intent = new Intent(Intent.ACTION_DIAL);
            intent.setData(Uri.parse("tel:" + phoneNumber));
            context.startActivity(intent);
        }
    }

    // 🔍 Filter donors
    public void filter(String query) {
        donorList.clear();

        if (query.isEmpty()) {
            donorList.addAll(donorListFull);
        } else {
            String pattern = query.toLowerCase().trim();
            for (Donor donor : donorListFull) {
                if (donor.getName().toLowerCase().contains(pattern) ||
                        donor.getBloodGroup().toLowerCase().contains(pattern)) {
                    donorList.add(donor);
                }
            }
        }
        notifyDataSetChanged();
    }

    // 🗑 Delete donor
    private void deleteDonor(String donorId, int position) {

        new AlertDialog.Builder(context)
                .setTitle("Confirm Delete")
                .setMessage("Are you sure you want to delete this donor?")
                .setPositiveButton("Yes", (dialog, which) -> {

                    AuthRequest request = new AuthRequest(
                            Request.Method.POST,
                            Config.DELETE_DONOR,
                            response -> {
                                Toast.makeText(context, "Donor deleted", Toast.LENGTH_SHORT).show();

                                if (position != RecyclerView.NO_POSITION) {
                                    donorList.remove(position);
                                    donorListFull.removeIf(d -> d.getId().equals(donorId));
                                    notifyItemRemoved(position);
                                }
                            },
                            error -> {
                                error.printStackTrace();
                                Toast.makeText(context, "Delete failed", Toast.LENGTH_SHORT).show();
                            },
                            context
                    ) {
                        @Override
                        protected java.util.Map<String, String> getParams() {
                            java.util.Map<String, String> params = new java.util.HashMap<>();
                            params.put("id", donorId);
                            return params;
                        }
                    };

                    Config.getInstance(context).addToRequestQueue(request);
                })
                .setNegativeButton("No", null)
                .show();
    }

    // ViewHolder
    public static class DonorViewHolder extends RecyclerView.ViewHolder {

        CircleImageView donorImage;
        TextView donorName, donorAddress, bloodGroup, donorPhone, textCall;
        LottieAnimationView lottieCall;
        LinearLayout bottomRow;
        AppCompatButton btnEdit, btnDelete;

        public DonorViewHolder(@NonNull View itemView) {
            super(itemView);

            donorImage = itemView.findViewById(R.id.donor_image);
            donorName = itemView.findViewById(R.id.donor_name);
            donorAddress = itemView.findViewById(R.id.donor_address);
            bloodGroup = itemView.findViewById(R.id.blood_group);
            donorPhone = itemView.findViewById(R.id.donor_phone);
            textCall = itemView.findViewById(R.id.text_call);
            lottieCall = itemView.findViewById(R.id.lottie_call);
            bottomRow = itemView.findViewById(R.id.bottom_row);
            btnEdit = itemView.findViewById(R.id.btn_edit);
            btnDelete = itemView.findViewById(R.id.btn_delete);
        }
    }
}
